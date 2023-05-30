package main

import (
	"archive/tar"
	"crypto/sha256"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strconv"
	"syscall"

	"github.com/docker/docker/pkg/tarsum"
)

var pathA = flag.String("pathA", "", "")
var pathB = flag.String("pathB", "", "")
var plan = flag.String("plan", "", "")
var pathA_file map[string]string
var pathA_pro map[string]string

func Walk(dirPath string, flag bool) {
	var dirs []string
	dir, err := ioutil.ReadDir(dirPath)
	if err != nil {
		fmt.Println(err)
		return
	}

	PthSep := string(os.PathSeparator)

	for _, fi := range dir {
		if fi.IsDir() {
			dirs = append(dirs, dirPath+PthSep+fi.Name())
			Walk(dirPath+PthSep+fi.Name(), flag)
		} else {
			info, err := os.Stat(dirPath + PthSep + fi.Name())
			if err != nil {
				//fmt.Println(dirPath + PthSep + fi.Name())
				continue
			}
			file_sys := info.Sys()
			name := info.Name()
			mode := fmt.Sprint(info.Mode())
			Uid := fmt.Sprint(file_sys.(*syscall.Stat_t).Uid)
			Gid := fmt.Sprint(file_sys.(*syscall.Stat_t).Gid)
			size := fmt.Sprint(info.Size())
			//typeflag := fmt.Sprint(file_sys.(*syscall.Stat_t).typeflag)
			//linkname := fmt.Sprint(file_sys.(*syscall.Stat_t).linkname)
			//uname := fmt.Sprint(file_sys.(*syscall.Stat_t).uname)
			//gname := fmt.Sprint(file_sys.(*syscall.Stat_t).gname)
			//devminor := fmt.Sprint(file_sys.(*syscall.Stat_t).devminor)
			//devmajor := fmt.Sprint(file_sys.(*syscall.Stat_t).devmajor)
			//fmt.Print(name + mode + Uid + Gid + size + "\n") //+ typeflag + linkname + uname + gname + devmajor + devminor

			content, err := os.ReadFile(dirPath + PthSep + fi.Name())
			sha256Content := [32]byte{}
			if err == nil {
				sha256Content = sha256.Sum256(content)
			}

			if flag == true {
				pathName := (dirPath + PthSep + fi.Name())[len(*pathA):]
				pathA_file[pathName] = name + mode + Uid + Gid + size + fmt.Sprint(sha256Content)
			} else {
				pathName := (dirPath + PthSep + fi.Name())[len(*pathB):]
				if pathA_file[pathName] != name+mode+Uid+Gid+size+fmt.Sprint(sha256Content) {
					fmt.Print(pathName + "\n")
					fmt.Print(pathA_file[pathName] + "\n")
					fmt.Print(name + mode + Uid + Gid + size + fmt.Sprint(sha256Content) + "\n")
				}
			}
		}
	}
}

func checkTar(tarR *tar.Reader, flag bool) {
	for h, err := tarR.Next(); err == nil; h, err = tarR.Next() {
		pro := h.Name + " " + strconv.FormatInt(h.Mode, 10) + " " + strconv.Itoa(h.Uid) + " " + strconv.Itoa(h.Gid) + " " + strconv.FormatInt(h.Size, 10) + " " + string([]byte{h.Typeflag}) + " " + h.Linkname + " " + h.Uname + " " + h.Gname + " " + strconv.FormatInt(h.Devmajor, 10) + " " + strconv.FormatInt(h.Devminor, 10)
		if flag == true {
			pathA_file[h.Name] = pro
		} else if pathA_file[h.Name] != pro {
			fmt.Print(h)
			fmt.Print(pro)
		}
	}
}

func main() {
	pathA_file = make(map[string]string)
	pathA_pro = make(map[string]string)

	flag.Parse()

	if *plan == "A" {
		tmp, _ := os.Open(*pathA)

		newTarSum, _ := tarsum.NewTarSum(tmp, true, tarsum.Version1)
		io.Copy(ioutil.Discard, newTarSum)
		fmt.Println(newTarSum.Sum(nil))
		// tarA := tar.NewReader(tmp)

		// checkTar(tarA, true)

		tmp, _ = os.Open(*pathA)

		newTarSum, _ = tarsum.NewTarSum(tmp, true, tarsum.Version0)
		io.Copy(ioutil.Discard, newTarSum)
		fmt.Println(newTarSum.Sum(nil))

		// tarB := tar.NewReader(tmp)

		// checkTar(tarB, false)
	} else {
		Walk(*pathA, true)
		Walk(*pathB, false)
	}
}
