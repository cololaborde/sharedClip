go build -o miapp goserver.go
nohup ./miapp > output.log 2>&1 &
