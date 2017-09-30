#include <iostream>

// Serial ports are complicated
#include <unistd.h>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <signal.h>
#include <setjmp.h>
#include <sys/ioctl.h>
#include <sys/types.h>

using namespace std;

int connect(string port = "/dev/ttyACM0"){
	int serial_fd;
	
	struct termios toptions;

        serial_fd = open(port.c_str(), O_RDWR | O_NOCTTY | O_NDELAY);
        if (serial_fd == -1){
                return -1;
        }

        if(tcgetattr(serial_fd, &toptions) < 0){
                return -2;
        }
        speed_t brate = B9600; //Baud rate to 9600                                                                                                                                                                                           
        cfsetispeed(&toptions, brate);
        cfsetospeed(&toptions, brate);

        toptions.c_cflag &= ~PARENB;
        toptions.c_cflag &= ~CSTOPB;
        toptions.c_cflag &= ~CSIZE;
        toptions.c_cflag |= CS8;
        toptions.c_cflag &= ~CRTSCTS;
        toptions.c_cflag |= CREAD | CLOCAL;
        toptions.c_iflag &= ~(IXON | IXOFF | IXANY);
        toptions.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
        toptions.c_oflag &= ~OPOST;

        toptions.c_cc[VMIN]  = 0;
        toptions.c_cc[VTIME] = 20;

	if(tcsetattr(serial_fd, TCSANOW, &toptions) < 0){
                return -4;
	}

        return serial_fd;
}

int write_char(int serial_fd, char c){
	return write(serial_fd, &c, 1) == 1 ? 0 : -1;
}

int read_char(int serial_fd, char * c){
	return read(serial_fd, c, 1) == 1 ? 0 : -1;
}

int main(int argc, char* argv[]){

	int serial_fd = connect();
	if(serial_fd < 0){
		return -1;
	}

	for(int i = 0; i < 256; i++){
		usleep(1000);
		write_char(serial_fd, (char) i);
		usleep(1000);
		write_char(serial_fd, 13);
		usleep(1000);
		write_char(serial_fd, (char) i);
	}

	for(int d = 0; d < 2; d++){
		for(int i = 0; i < 32; i++){
			for(int j = i*8; j < i*8+8; j++){
				write_char(serial_fd, (char) j);
				usleep(1000);
				write_char(serial_fd, 8);
				usleep(1000);
				char c;
				read_char(serial_fd, &c);
				cout << j << ":" << (int) (unsigned char) c << "\t";
				usleep(1000);
			}
			cout << "\n";
		}
	}

	return 0;
}

