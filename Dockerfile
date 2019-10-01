FROM mcr.microsoft.com/windows/servercore
MAINTAINER Pollen Metrology <admin-team@pollen-metrology.com>

# Will be used for agent.jar retrieval
ARG JENKINS_VERSION=3.35

# Install Chocolatey package manager
# see https://chocolatey.org/
RUN powershell.exe Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# install needed packages
RUN choco install -y --no-progress python
RUN choco install -y --no-progress server-jre8
RUN choco install -y --no-progress nodejs-lts
RUN choco install -y --no-progress yarn
RUN choco install -y --no-progress visualcppbuildtools
RUN choco install -y --no-progress vcbuildtools
RUN choco install -y --no-progress cmake
RUN choco install -y --no-progress git
RUN choco install -y --no-progress curl
RUN choco install -y --no-progress vim
RUN choco install -y --no-progress openssh
RUN choco install -y --no-progress doxygen.install

# Install needed *Python* tools and packages
RUN refreshenv
RUN python -m pip install conan

#
# Hacks for Git via SSH works in the Windows container
#
# We will use c:\jks as Jenkins home
#
RUN mkdir c:\jks

# Download Jenkins booststrap
RUN curl -fsSLo c:\jks\agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/%JENKINS_VERSION%/remoting-%JENKINS_VERSION%.jar

# 1. Fixing permissions (per https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH) 
# RUN Powershell.exe -ExecutionPolicy Bypass -Command ". c:\Program Files\OpenSSH-Win64\FixHostFilePermissions.ps1 -Confirm:$false" 

# 2. overrides the SSH version that comes with GIT 
RUN copy "c:\Program Files\OpenSSH-Win64\ssh*.exe" "c:\Program Files\Git\usr\bin" /y

# 3. Fix permissions so that temporary ssh keys will not have
# too weak permissions, and avoid "WARNING: UNPROTECTED PRIVATE KEY FILE!"

# Allow default Docker user
RUN cacls c:\jks /E /G "ContainerAdministrator":F

# revoke all other entries
RUN cacls c:\jks /E /R "BUILTIN\Users"
RUN cacls c:\jks /E /R "NT AUTHORITY\Authenticated Users"
RUN cacls c:\jks /E /R "BUILTIN\Administrators"
RUN cacls c:\jks /E /R "NT AUTHORITY\SYSTEM"

# Create cache folder for Yarn
RUN mkdir c:\dev\cache\yarn

# Fix system Path
RUN setx PATH "c:\Program Files\CMake\bin;%PATH%"
