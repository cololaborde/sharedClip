#get from .env port, host and url for file

export $(grep -v '^#' .env | xargs)

if lsof -i :$PORT; then
  pid=$(lsof -ti :$PORT)
  echo "El puerto $PORT ya está en uso. Matando proceso $pid."
  kill -9 $pid
fi

HOST=$HOST
FILE=$FILE

echo "Compilando el servidor Go..."
go build -o miapp goserver.go
nohup ./miapp -host=$HOST -port=$PORT -file=$FILE > output.log 2>&1 &
echo "Servidor Go iniciado en segundo plano."