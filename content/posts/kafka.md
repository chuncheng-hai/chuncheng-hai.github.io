

## 基础环境准备

https://www.oracle.com/in/java/technologies/downloads/archive/ 下载jdk
```bash
mkdir -p /opt/java/

wget https://mirrors.tuna.tsinghua.edu.cn/Adoptium/17/jdk/x64/linux/OpenJDK17U-jdk_x64_linux_hotspot_17.0.18_8.tar.gz
tar -xf OpenJDK17U-jdk_x64_linux_hotspot_17.0.18_8.tar.gz
ln -s /opt/java/jdk-17.0.18+8 /opt/java/current

cat <<'EOF' | sudo tee /etc/profile.d/java.sh
export JAVA_HOME=/opt/java/current
export PATH=$JAVA_HOME/bin:$PATH
EOF
source /etc/profile.d/java.sh

java -version
echo $JAVA_HOME

cat >> /etc/hosts <<EOF
192.168.1.10 zk1
192.168.1.11 zk2
192.168.1.12 zk3

192.168.1.20 kafka1
192.168.1.21 kafka2
192.168.1.22 kafka3
EOF
```


## 部署 ZooKeeper 集群
```bash
cd /opt
wget https://downloads.apache.org/zookeeper/zookeeper-3.9.2/apache-zookeeper-3.9.2-bin.tar.gz

tar -xzf apache-zookeeper-3.9.2-bin.tar.gz
ln -s apache-zookeeper-3.9.2-bin zookeeper

mkdir -p /data/zookeeper/{data,logs}
cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg
vi /opt/zookeeper/conf/zoo.cfg
tickTime=2000
initLimit=10
syncLimit=5

dataDir=/data/zookeeper/data
dataLogDir=/data/zookeeper/logs

clientPort=2181

server.1=zk1:2888:3888
server.2=zk2:2888:3888
server.3=zk3:2888:3888

echo 1 > /data/zookeeper/data/myid   # zk1
echo 2 > /data/zookeeper/data/myid   # zk2
echo 3 > /data/zookeeper/data/myid   # zk3

cat > /etc/systemd/system/zookeeper.service <<EOF
[Unit]
Description=Zookeeper
After=network.target

[Service]
ExecStart=/opt/zookeeper/bin/zkServer.sh start-foreground
ExecStop=/opt/zookeeper/bin/zkServer.sh stop
Restart=always

[Install]
WantedBy=multi-user.target
EOF

/opt/zookeeper/bin/zkServer.sh start
/opt/zookeeper/bin/zkServer.sh status
```

## 部署 Kafka

```bash
cd /opt
wget https://downloads.apache.org/kafka/3.7.0/kafka_2.13-3.7.0.tgz

tar -xzf kafka_2.13-3.7.0.tgz
ln -s kafka_2.13-3.7.0 kafka

# 创建数据目录
mkdir -p /data/kafka/logs

vi /opt/kafka/config/server.properties
broker.id=1

listeners=PLAINTEXT://192.168.1.20:9092
advertised.listeners=PLAINTEXT://192.168.1.20:9092

log.dirs=/data/kafka/logs

num.network.threads=8
num.io.threads=16

socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400

log.retention.hours=168

zookeeper.connect=zk1:2181,zk2:2181,zk3:2181

cat > /etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Kafka
After=zookeeper.service

[Service]
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

/opt/kafka/bin/kafka-server-start.sh -daemon \
/opt/kafka/config/server.properties
```

Environment="JAVA_HOME=/opt/java/current"
Environment="PATH=/opt/java/current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"

```bash
/opt/zookeeper/bin/zkCli.sh

ls /

# 创建 Topic
/opt/kafka/bin/kafka-topics.sh \
--create \
--topic test \
--bootstrap-server 192.168.1.20:9092 \
--partitions 3 \
--replication-factor 3

# 生产消息
/opt/kafka/bin/kafka-console-producer.sh \
--topic test \
--bootstrap-server 192.168.1.20:9092

# 消费消息
/opt/kafka/bin/kafka-console-consumer.sh \
--topic test \
--from-beginning \
--bootstrap-server 192.168.1.20:9092
```