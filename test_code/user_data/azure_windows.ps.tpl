<powershell>
# Execute it with elevated permissions
# Description: 
# This script install automatically the open-ssh feature and enable it

# enable tls1.2 for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# creating openssh folder and download the zip
mkdir c:\openssh-install 
cd c:\openssh-install

#update the last version if you want the last release
Invoke-WebRequest -Uri "https://github.com/PowerShell/Win32-OpenSSH/releases/download/V8.6.0.0p1-Beta/OpenSSH-Win64.zip" -OutFile .\openssh.zip
Expand-Archive .\openssh.zip -DestinationPath .\openssh\
cd .\openssh\OpenSSH-Win64\

# required for enable the service
setx PATH "$env:path;c:\openssh-install\openssh\OpenSSH-Win64\" -m

# required for install the service
powershell.exe -ExecutionPolicy Bypass -File install-sshd.ps1

# required for execute remote connections
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

net start sshd

# auto enable for each restart machine
Set-Service sshd -StartupType Automatic

#Set default shell to powershell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# Configure SSH for the specific user "test-user" with public key "12345"
$sshUser = "test-user"
$sshPublicKey = "${var.public_key}"
$sshUserPath = "C:\ProgramData\ssh\administrators_authorized_keys"

# Append the public key to the authorized_keys file for the user
Add-Content -Path $sshUserPath -Value "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC12345"

# Restart the sshd service to apply the changes
Restart-Service sshd
</powershell>
<persist>true</persist>