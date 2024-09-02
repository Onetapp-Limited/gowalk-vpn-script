Requirements for server:
Ubuntu 18.04

1) Setup local ssh config
mkdir -p ~/.ssh && echo "Host *" > ~/.ssh/config && echo " StrictHostKeyChecking no" >> ~/.ssh/config && chmod 400 ~/.ssh/config

2) Setup sshpass on your local:
curl -L https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb > sshpass.rb && brew install sshpass.rb && rm sshpass.rb

3) Run install script (change pass, user, ip):
sshpass -p pass ssh -t user@ip 'wget --header="Authorization: token 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" https://raw.githubusercontent.com/gasabdullaev/vpn/HEAD/createvpn.sh -O createvpn.sh && chmod +x createvpn.sh && bash createvpn.sh'

4) When finished copy sertificate & Paste info Firebase Database

HOW REMOTE UPDATE VPN
1) Commit scripts into section in update.sh
2) Wait few minutes, all servers will be auto-updated