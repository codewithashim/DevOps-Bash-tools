#!/usr/bin/env bash
# shellcheck disable=SC2015
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-11-07 14:25:06 +0000 (Thu, 07 Nov 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

# https://aws.amazon.com/blogs/aws/new-ec2-spot-instance-termination-notices/

# Executes the arguments as shell commands when the EC2 instance running this script is notified of Spot Termination
#
# Can be used as a latch mechanism to wait before allowing a shell or script to proceed past calling this script

# Usage:
#
#  ./aws_spot_when_terminated_execute.sh "command1; command2; command 3"        All commands execute in a subshell
#
#  ./aws_spot_when_terminated_execute.sh; command 1; command2; command 3        All commands execute in current shell
#                                                                       (notice the semi-colon immediately after the script giving it no argument, merely using it as a latch mechanism)
#
#  ./aws_spot_when_terminated_execute.sh command1; command2; command 3          First command executes in the subshell (it's an argument). Commands 2 & 3 execute in the current shell after this script
#
#  ./aws_spot_when_terminated_execute.sh 'x=test; echo $x'                      Variable is interpolated inside the single quotes at runtime after receiving Spot Termination notice
#

# Inspired by whenup() / whendown() for hosts and whendone() for processes from interactive bash library .bash.d/* sourced as part of the .bashrc in this repo
#
# You can trigger this as part of rc.local or similar on an EC2 Spot instance and when it gets the termination notice it'll execute all of its arguments as commands

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

termination_time=""

while true; do
    # regex borrowed from AWS Systems Administration book by O'Reilly and also here:
    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html
    termination_time="$(curl -s --max-time 1 http://169.254.169.254/latest/meta-data/spot/termination-time | grep '.*T.*Z' || :)"
    if [ -n "$termination_time" ]; then
        break
    fi
    echo -n '.'
    # AWS recommended check interval
    sleep 5
done

echo "Termination Time:  $termination_time"
echo "Executing:  $*"
# eval'ing so that "command1; command2" works as well as 'x=test; echo $x'
eval "$@"
