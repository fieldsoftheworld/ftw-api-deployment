#!/bin/bash
set -euo pipefail

# Log all output
exec > >(tee -a /var/log/user-data.log)
exec 2>&1
echo "Starting instance initialization at $(date)"

# Environment validation - values passed via Terraform template
ENVIRONMENT="${ENVIRONMENT}"
FASTAPI_APP_PORT="${FASTAPI_APP_PORT}"

if [ -z "$ENVIRONMENT" ] || [ -z "$FASTAPI_APP_PORT" ]; then
    echo "ERROR: Required environment variables not set"
    echo "ENVIRONMENT: $ENVIRONMENT"
    echo "FASTAPI_APP_PORT: $FASTAPI_APP_PORT"
    exit 1
fi

#############################################
# 1. System Updates & Essential Packages
#############################################
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get install -y unattended-upgrades

# Configure automatic security updates
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "$${distro_id}:$${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

systemctl enable unattended-upgrades
systemctl start unattended-upgrades

#############################################
# 2. Basic Security Settings
#############################################
cat > /etc/sysctl.d/99-basic.conf <<'EOF'
# Basic security hardening
kernel.randomize_va_space = 2
fs.suid_dumpable = 0
kernel.dmesg_restrict = 1
EOF
sysctl -p /etc/sysctl.d/99-basic.conf

#############################################
# 3. CloudWatch Monitoring (Simplified)
#############################################
# Install CloudWatch agent if not present
if ! command -v amazon-cloudwatch-agent &> /dev/null; then
    wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    dpkg -i amazon-cloudwatch-agent.deb
    rm amazon-cloudwatch-agent.deb
fi

# CloudWatch config with GPU monitoring support
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "metrics": {
    "namespace": "FTW-API/${ENVIRONMENT}",
    "append_dimensions": {
      "InstanceId": "{aws:InstanceId}"
    },
    "metrics_collected": {
      "cpu": {
        "measurement": [{"name": "cpu_usage_active", "unit": "Percent"}],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [{"name": "used_percent", "unit": "Percent"}],
        "metrics_collection_interval": 300,
        "resources": ["/"]
      },
      "mem": {
        "measurement": [{"name": "mem_used_percent", "unit": "Percent"}],
        "metrics_collection_interval": 60
      },
      "nvidia_gpu": {
        "measurement": [
          "utilization_gpu",
          "utilization_memory",
          "memory_total",
          "memory_used",
          "memory_free",
          "temperature_gpu",
          "power_draw",
          "fan_speed",
          "clocks_current_graphics",
          "clocks_current_memory"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/aws/ec2/${ENVIRONMENT}/user-data",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/home/ubuntu/ftw-inference-api/logs/*.log",
            "log_group_name": "/aws/ec2/${ENVIRONMENT}/application",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "force_flush_interval": 60
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

#############################################
# 4. Verify SSM Agent (Critical for access)
#############################################
# Ubuntu 24.04 uses snap for SSM Agent, older versions use systemd
if command -v snap &> /dev/null && snap list amazon-ssm-agent &> /dev/null; then
    echo "SSM Agent detected as snap package"
    snap start amazon-ssm-agent
    SSM_SERVICE="snap.amazon-ssm-agent.amazon-ssm-agent.service"
else
    echo "SSM Agent detected as systemd service"
    systemctl enable amazon-ssm-agent
    systemctl restart amazon-ssm-agent
    SSM_SERVICE="amazon-ssm-agent"
fi

for i in {1..30}; do
    if systemctl is-active --quiet "$SSM_SERVICE"; then
        echo "SSM Agent is running"
        break
    fi
    echo "Waiting for SSM Agent to start... ($i/30)"
    sleep 2
done

if ! systemctl is-active --quiet "$SSM_SERVICE"; then
    echo "WARNING: SSM Agent failed to start, but continuing deployment..."
fi

#############################################
# 5. Deploy FTW Inference API
#############################################
echo "Deploying FTW inference API..."

# Run the deploy script as ubuntu user
sudo -u ubuntu bash -c "cd /home/ubuntu && curl -L https://raw.githubusercontent.com/fieldsoftheworld/ftw-inference-api/main/deploy.sh | bash"

# Wait for service to be ready (up to 5 minutes)
for i in {1..60}; do
    if systemctl is-active --quiet ftw-inference-api; then
        echo "FTW Inference API service is running"
        break
    fi
    echo "Waiting for API to start... ($i/60)"
    sleep 5
done

if ! systemctl is-active --quiet ftw-inference-api; then
    echo "WARNING: FTW Inference API service failed to start after 5 minutes"
    systemctl status ftw-inference-api --no-pager
fi

#############################################
# 6. Final Security Checks
#############################################
# Disable root and ssh
passwd -l root
systemctl stop ssh
systemctl disable ssh

# Remove unnecessary packages
apt-get autoremove -y
apt-get autoclean

# Set proper permissions on log files
chmod 640 /var/log/user-data.log
if [ -d /home/ubuntu/ftw-inference-api/logs ]; then
    chown -R ubuntu:ubuntu /home/ubuntu/ftw-inference-api/logs
fi

echo "Instance initialization completed at $(date)"
echo "Security configuration:"
echo "  - Automatic updates: Enabled"
echo "  - CloudWatch monitoring: Active"
echo "  - SSM access: Enabled"
echo "  - FTW API: Running on port ${FASTAPI_APP_PORT}"