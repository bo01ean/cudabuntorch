# cudabuntorch

Want to easily and seamlessly install Torch on your Ubuntu/Cuda machines?

Me too. Let's go:

## To run on a native host (ubuntu >= 16.04):
```
git clone https://github.com/bo01ean/cudabuntorch /tmp/cudabuntorch
cd /tmp/cudabuntorch
sudo torch=yes ./install.sh

```

## To do a test run with Docker, install Docker first then:
```
git clone https://github.com/bo01ean/cudabuntorch /tmp/cudabuntorch
cd /tmp/cudabuntorch
sudo torch=yes ./dockergo.sh
```
