cd /opt
wget https://www.python.org/ftp/python/3.7.9/Python-3.7.9.tgz
tar xzf Python-3.7.9.tgz
cd Python-3.7.9
./configure --enable-optimizations
make altinstall
rm ../Python-3.7.9.tgz -f
python3.7 /tmp/get-pip.py
pip3.7 install six psutil lxml pyopenssl
