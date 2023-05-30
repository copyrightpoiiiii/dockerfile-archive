# !/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# mkdir $DIR/p1-out
# mkdir $DIR/p2-out
# mkdir $DIR/p3-out
# mkdir $DIR/p4-out
echo "prase1"
docker run -it --rm -v "${DIR}/inputs:/mnt/inputs" -v "${DIR}/p1-out:/mnt/outputs" prase1:v3
echo "prase2"
docker run -it --rm -v "${DIR}/p1-out:/mnt/inputs" -v "${DIR}/p2-out:/mnt/outputs" prase2:v4
echo "middleware"
python3 work.py middleware
echo "parse3"
docker run -it --rm -v "${DIR}/p2-out:/mnt/inputs" -v "${DIR}/p3-out:/mnt/outputs" prase3:v10
echo "work"
python3 work.py work
# docker run -it --rm -v "${DIR}/p3-out:/mnt/inputs" -v "${DIR}/p4-out:/mnt/outputs" prase4:v1