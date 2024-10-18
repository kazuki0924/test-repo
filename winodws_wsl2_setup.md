# Setup

TBD

Windows
```
wsl --install
```

Ubuntu内
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /home/ubuntu/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/ubuntu/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
sudo apt-get install build-essential
brew install gcc
brew install docker docker-compose docker-buildx
sudo apt update
sudo apt install docker.io
sudo groupadd docker
sudo usermod -aG docker $USER
sudo service docker start
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
export AWS_DEFAULT_REGION="ap-northeast-1"
SSO_START_URL="https://d-95671c43b1.awsapps.com/start/#"
AWS_ACCOUNT_ID="590183837533"
PROFILE_NAME="xev-vpp-evems-dev"
ROLE_NAME="AdministratorAccess"
aws configure --profile "${PROFILE_NAME}" set sso_start_url "${SSO_START_URL}"
aws configure --profile "${PROFILE_NAME}" set sso_region "${AWS_DEFAULT_REGION}"
aws configure --profile "${PROFILE_NAME}" set sso_account_id "${AWS_ACCOUNT_ID}"
aws configure --profile "${PROFILE_NAME}" set sso_role_name "${ROLE_NAME}"
aws sso login --profile "${PROFILE_NAME}"
gh repo clone wcm-eas/xev-vpp-infra-templates
cd xev-vpp-infra-templates
code .
```
