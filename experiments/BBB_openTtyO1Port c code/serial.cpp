/*
    To compile:
    g++ serial.cpp -o openTtyO1Port.exe
*/

#include <stdio.h>
#include "serialib.h"


#if defined (_WIN32) || defined( _WIN64)
#define         DEVICE_PORT             "COM1"                               // COM1 for windows
#endif

#ifdef __linux__
#define         DEVICE_PORT             "/dev/ttyO1"                         // ttyS0 for linux
#endif


/*!

 \file    serialib.cpp

 \brief   Class to manage the serial port

 \author  Philippe Lucidarme (University of Angers) <serialib@googlegroups.com>

 \version 1.2

 \date    28 avril 2011



THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,

INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR

PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE X CONSORTIUM BE LIABLE FOR ANY CLAIM,

DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING

FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.





This is a licence-free software, it can be used by anyone who try to build a better world.

 */



#include "serialib.h"









/*!

    \brief      Constructor of the class serialib.

*/

// Class constructor

serialib::serialib()

{}





/*!

    \brief      Destructor of the class serialib. It close the connection

*/

// Class desctructor

serialib::~serialib()

{

    Close();

}







//_________________________________________

// ::: Configuration and initialization :::







/*!

     \brief Open the serial port

     \param Device : Port name (COM1, COM2, ... for Windows ) or (/dev/ttyS0, /dev/ttyACM0, /dev/ttyUSB0 ... for linux)

     \param Bauds : Baud rate of the serial port.



                \n Supported baud rate for Windows :

                        - 110

                        - 300

                        - 600

                        - 1200

                        - 2400

                        - 4800

                        - 9600

                        - 14400

                        - 19200

                        - 38400

                        - 56000

                        - 57600

                        - 115200

                        - 128000

                        - 256000



               \n Supported baud rate for Linux :\n

                        - 110

                        - 300

                        - 600

                        - 1200

                        - 2400

                        - 4800

                        - 9600

                        - 19200

                        - 38400

                        - 57600

                        - 115200



     \return 1 success

     \return -1 device not found

     \return -2 error while opening the device

     \return -3 error while getting port parameters

     \return -4 Speed (Bauds) not recognized

     \return -5 error while writing port parameters

     \return -6 error while writing timeout parameters

  */

char serialib::Open(const char *Device,const unsigned int Bauds)

{

#if defined (_WIN32) || defined( _WIN64)



    // Open serial port

    hSerial = CreateFileA(  Device,GENERIC_READ | GENERIC_WRITE,0,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);

    if(hSerial==INVALID_HANDLE_VALUE) {

        if(GetLastError()==ERROR_FILE_NOT_FOUND)

            return -1;                                                  // Device not found

        return -2;                                                      // Error while opening the device

    }



    // Set parameters

    DCB dcbSerialParams = {0};                                          // Structure for the port parameters

    dcbSerialParams.DCBlength=sizeof(dcbSerialParams);

    if (!GetCommState(hSerial, &dcbSerialParams))                       // Get the port parameters

        return -3;                                                      // Error while getting port parameters

    switch (Bauds)                                                      // Set the speed (Bauds)

    {

    case 110  :     dcbSerialParams.BaudRate=CBR_110; break;

    case 300  :     dcbSerialParams.BaudRate=CBR_300; break;

    case 600  :     dcbSerialParams.BaudRate=CBR_600; break;

    case 1200 :     dcbSerialParams.BaudRate=CBR_1200; break;

    case 2400 :     dcbSerialParams.BaudRate=CBR_2400; break;

    case 4800 :     dcbSerialParams.BaudRate=CBR_4800; break;

    case 9600 :     dcbSerialParams.BaudRate=CBR_9600; break;

    case 14400 :    dcbSerialParams.BaudRate=CBR_14400; break;

    case 19200 :    dcbSerialParams.BaudRate=CBR_19200; break;

    case 38400 :    dcbSerialParams.BaudRate=CBR_38400; break;

    case 56000 :    dcbSerialParams.BaudRate=CBR_56000; break;

    case 57600 :    dcbSerialParams.BaudRate=CBR_57600; break;

    case 115200 :   dcbSerialParams.BaudRate=CBR_115200; break;

    case 128000 :   dcbSerialParams.BaudRate=CBR_128000; break;

    case 256000 :   dcbSerialParams.BaudRate=CBR_256000; break;

    default : return -4;

}    

    dcbSerialParams.ByteSize=8;                                         // 8 bit data

    dcbSerialParams.StopBits=ONESTOPBIT;                                // One stop bit

    dcbSerialParams.Parity=NOPARITY;                                    // No parity

    if(!SetCommState(hSerial, &dcbSerialParams))                        // Write the parameters

        return -5;                                                      // Error while writing



    // Set TimeOut

    timeouts.ReadIntervalTimeout=0;                                     // Set the Timeout parameters

    timeouts.ReadTotalTimeoutConstant=MAXDWORD;                         // No TimeOut

    timeouts.ReadTotalTimeoutMultiplier=0;

    timeouts.WriteTotalTimeoutConstant=MAXDWORD;

    timeouts.WriteTotalTimeoutMultiplier=0;

    if(!SetCommTimeouts(hSerial, &timeouts))                            // Write the parameters

        return -6;                                                      // Error while writting the parameters

    return 1;                                                           // Opening successfull



#endif

#ifdef __linux__    

    struct termios options;                                             // Structure with the device's options





    // Open device

    fd = open(Device, O_RDWR | O_NOCTTY | O_NDELAY);                    // Open port

    if (fd == -1) return -2;                                            // If the device is not open, return -1

    fcntl(fd, F_SETFL, FNDELAY);                                        // Open the device in nonblocking mode



    // Set parameters

    tcgetattr(fd, &options);                                            // Get the current options of the port

    bzero(&options, sizeof(options));                                   // Clear all the options

    speed_t         Speed;

    switch (Bauds)                                                      // Set the speed (Bauds)

    {

    case 110  :     Speed=B110; break;

    case 300  :     Speed=B300; break;

    case 600  :     Speed=B600; break;

    case 1200 :     Speed=B1200; break;

    case 2400 :     Speed=B2400; break;

    case 4800 :     Speed=B4800; break;

    case 9600 :     Speed=B9600; break;

    case 19200 :    Speed=B19200; break;

    case 38400 :    Speed=B38400; break;

    case 57600 :    Speed=B57600; break;

    case 115200 :   Speed=B115200; break;

    default : return -4;

}

    cfsetispeed(&options, Speed);                                       // Set the baud rate at 115200 bauds
    cfsetospeed(&options, Speed);
    options.c_cflag |= ( CLOCAL | CREAD |  CS8);                        // Configure the device : 8 bits, no parity, no control
    options.c_iflag |= ( IGNPAR | IGNBRK );
    options.c_cc[VTIME]=0;                                              // Timer unused
    options.c_cc[VMIN]=0;                                               // At least on character before satisfy reading
    tcsetattr(fd, TCSANOW, &options);                                   // Activate the settings
    return (1);                                                         // Success
#endif
}





/*!

     \brief Close the connection with the current device

*/

void serialib::Close()

{

#if defined (_WIN32) || defined( _WIN64)

    CloseHandle(hSerial);

#endif

#ifdef __linux__

    close (fd);

#endif

}









//___________________________________________

// ::: Read/Write operation on characters :::







/*!

     \brief Write a char on the current serial port

     \param Byte : char to send on the port (must be terminated by '\0')

     \return 1 success

     \return -1 error while writting data

  */

char serialib::WriteChar(const char Byte)

{

#if defined (_WIN32) || defined( _WIN64)

    DWORD dwBytesWritten;                                               // Number of bytes written

    if(!WriteFile(hSerial,&Byte,1,&dwBytesWritten,NULL))                // Write the char

        return -1;                                                      // Error while writing

    return 1;                                                           // Write operation successfull

#endif

#ifdef __linux__

    if (write(fd,&Byte,1)!=1)                                           // Write the char

        return -1;                                                      // Error while writting

    return 1;                                                           // Write operation successfull

#endif

}







//________________________________________

// ::: Read/Write operation on strings :::





/*!

     \brief Write a string on the current serial port

     \param String : string to send on the port (must be terminated by '\0')

     \return 1 success

     \return -1 error while writting data

  */

char serialib::WriteString(const char *String)

{

#if defined (_WIN32) || defined( _WIN64)

    DWORD dwBytesWritten;                                               // Number of bytes written

    if(!WriteFile(hSerial,String,strlen(String),&dwBytesWritten,NULL))  // Write the string

        return -1;                                                      // Error while writing

    return 1;                                                           // Write operation successfull

#endif

#ifdef __linux__

    int Lenght=strlen(String);                                          // Lenght of the string

    if (write(fd,String,Lenght)!=Lenght)                                // Write the string

        return -1;                                                      // error while writing

    return 1;                                                           // Write operation successfull

#endif

}



// _____________________________________

// ::: Read/Write operation on bytes :::







/*!

     \brief Write an array of data on the current serial port

     \param Buffer : array of bytes to send on the port

     \param NbBytes : number of byte to send

     \return 1 success

     \return -1 error while writting data

  */

char serialib::Write(const void *Buffer, const unsigned int NbBytes)

{

#if defined (_WIN32) || defined( _WIN64)

    DWORD dwBytesWritten;                                               // Number of byte written

    if(!WriteFile(hSerial, Buffer, NbBytes, &dwBytesWritten, NULL))     // Write data

        return -1;                                                      // Error while writing

    return 1;                                                           // Write operation successfull

#endif

#ifdef __linux__

    if (write (fd,Buffer,NbBytes)!=(ssize_t)NbBytes)                              // Write data

        return -1;                                                      // Error while writing

    return 1;                                                           // Write operation successfull

#endif

}







/*!

     \brief Wait for a byte from the serial device and return the data read

     \param pByte : data read on the serial device

     \param TimeOut_ms : delay of timeout before giving up the reading

            If set to zero, timeout is disable (Optional)

     \return 1 success

     \return 0 Timeout reached

     \return -1 error while setting the Timeout

     \return -2 error while reading the byte

  */

char serialib::ReadChar(char *pByte,unsigned int TimeOut_ms)

{

#if defined (_WIN32) || defined(_WIN64)



    DWORD dwBytesRead = 0;

    timeouts.ReadTotalTimeoutConstant=TimeOut_ms;                       // Set the TimeOut

    if(!SetCommTimeouts(hSerial, &timeouts))                            // Write the parameters

        return -1;                                                      // Error while writting the parameters

    if(!ReadFile(hSerial,pByte, 1, &dwBytesRead, NULL))                 // Read the byte

        return -2;                                                      // Error while reading the byte

    if (dwBytesRead==0) return 0;                                       // Return 1 if the timeout is reached

    return 1;                                                           // Success

#endif

#ifdef __linux__

    TimeOut         Timer;                                              // Timer used for timeout

    Timer.InitTimer();                                                  // Initialise the timer

    while (Timer.ElapsedTime_ms()<TimeOut_ms || TimeOut_ms==0)          // While Timeout is not reached

    {

        switch (read(fd,pByte,1)) {                                     // Try to read a byte on the device

        case 1  : return 1;                                             // Read successfull

        case -1 : return -2;                                            // Error while reading

        }

    }

    return 0;

#endif

}







/*!

     \brief Read a string from the serial device (without TimeOut)

     \param String : string read on the serial device

     \param FinalChar : final char of the string

     \param MaxNbBytes : maximum allowed number of bytes read

     \return >0 success, return the number of bytes read

     \return -1 error while setting the Timeout

     \return -2 error while reading the byte

     \return -3 MaxNbBytes is reached

  */

int serialib::ReadStringNoTimeOut(char *String,char FinalChar,unsigned int MaxNbBytes)

{

    unsigned int    NbBytes=0;                                          // Number of bytes read

    char            ret;                                                // Returned value from Read

    while (NbBytes<MaxNbBytes)                                          // While the buffer is not full

    {                                                                   // Read a byte with the restant time

        ret=ReadChar(&String[NbBytes]);

        if (ret==1)                                                     // If a byte has been read

        {

            if (String[NbBytes]==FinalChar)                             // Check if it is the final char

            {

                String  [++NbBytes]=0;                                  // Yes : add the end character 0

                return NbBytes;                                         // Return the number of bytes read

            }

            NbBytes++;                                                  // If not, just increase the number of bytes read

        }

        if (ret<0) return ret;                                          // Error while reading : return the error number

    }

    return -3;                                                          // Buffer is full : return -3

}



/*!

     \brief Read a string from the serial device (with timeout)

     \param String : string read on the serial device

     \param FinalChar : final char of the string

     \param MaxNbBytes : maximum allowed number of bytes read

     \param TimeOut_ms : delay of timeout before giving up the reading (optional)

     \return  >0 success, return the number of bytes read

     \return  0 timeout is reached

     \return -1 error while setting the Timeout

     \return -2 error while reading the byte

     \return -3 MaxNbBytes is reached

  */

int serialib::ReadString(char *String,char FinalChar,unsigned int MaxNbBytes,unsigned int TimeOut_ms)

{

    if (TimeOut_ms==0)

        return ReadStringNoTimeOut(String,FinalChar,MaxNbBytes);



    unsigned int    NbBytes=0;                                          // Number of bytes read

    char            ret;                                                // Returned value from Read

    TimeOut         Timer;                                              // Timer used for timeout

    long int        TimeOutParam;

    Timer.InitTimer();                                                  // Initialize the timer



    while (NbBytes<MaxNbBytes)                                          // While the buffer is not full

    {                                                                   // Read a byte with the restant time

        TimeOutParam=TimeOut_ms-Timer.ElapsedTime_ms();                 // Compute the TimeOut for the call of ReadChar

        if (TimeOutParam>0)                                             // If the parameter is higher than zero

        {

            ret=ReadChar(&String[NbBytes],TimeOutParam);                // Wait for a byte on the serial link            

            if (ret==1)                                                 // If a byte has been read

            {



                if (String[NbBytes]==FinalChar)                         // Check if it is the final char

                {

                    String  [++NbBytes]=0;                              // Yes : add the end character 0

                    return NbBytes;                                     // Return the number of bytes read

                }

                NbBytes++;                                              // If not, just increase the number of bytes read

            }

            if (ret<0) return ret;                                      // Error while reading : return the error number

        }

        if (Timer.ElapsedTime_ms()>TimeOut_ms) {                        // Timeout is reached

            String[NbBytes]=0;                                          // Add the end caracter

            return 0;                                                   // Return 0

        }

    }

    return -3;                                                          // Buffer is full : return -3

}





/*!

     \brief Read an array of bytes from the serial device (with timeout)

     \param Buffer : array of bytes read from the serial device

     \param MaxNbBytes : maximum allowed number of bytes read

     \param TimeOut_ms : delay of timeout before giving up the reading

     \return 1 success, return the number of bytes read

     \return 0 Timeout reached

     \return -1 error while setting the Timeout

     \return -2 error while reading the byte

  */

int serialib::Read (void *Buffer,unsigned int MaxNbBytes,unsigned int TimeOut_ms)

{

#if defined (_WIN32) || defined(_WIN64)

    DWORD dwBytesRead = 0;

    timeouts.ReadTotalTimeoutConstant=(DWORD)TimeOut_ms;                // Set the TimeOut

    if(!SetCommTimeouts(hSerial, &timeouts))                            // Write the parameters

        return -1;                                                      // Error while writting the parameters

    if(!ReadFile(hSerial,Buffer,(DWORD)MaxNbBytes,&dwBytesRead, NULL))  // Read the bytes from the serial device

        return -2;                                                      // Error while reading the byte

    if (dwBytesRead!=(DWORD)MaxNbBytes) return 0;                       // Return 0 if the timeout is reached

    return 1;                                                           // Success

#endif

#ifdef __linux__

    TimeOut          Timer;                                             // Timer used for timeout

    Timer.InitTimer();                                                  // Initialise the timer

    unsigned int     NbByteRead=0;

    while (Timer.ElapsedTime_ms()<TimeOut_ms || TimeOut_ms==0)          // While Timeout is not reached

    {

        unsigned char* Ptr=(unsigned char*)Buffer+NbByteRead;           // Compute the position of the current byte

        int Ret=read(fd,(void*)Ptr,MaxNbBytes-NbByteRead);              // Try to read a byte on the device

        if (Ret==-1) return -2;                                         // Error while reading

        if (Ret>0) {                                                    // One or several byte(s) has been read on the device

            NbByteRead+=Ret;                                            // Increase the number of read bytes

            if (NbByteRead>=MaxNbBytes)                                 // Success : bytes has been read

                return 1;

        }

    }

    return 0;                                                           // Timeout reached, return 0

#endif

}









// _________________________

// ::: Special operation :::







/*!

    \brief Empty receiver buffer (UNIX only)

*/



void serialib::FlushReceiver()

{

#ifdef __linux__

    tcflush(fd,TCIFLUSH);

#endif

}







/*!

    \brief  Return the number of bytes in the received buffer (UNIX only)

    \return The number of bytes in the received buffer

*/

int serialib::Peek()

{

    int Nbytes=0;

#ifdef __linux__

    ioctl(fd, FIONREAD, &Nbytes);

#endif

    return Nbytes;

}



// ******************************************

//  Class TimeOut

// ******************************************





/*!

    \brief      Constructor of the class TimeOut.

*/

// Constructor

TimeOut::TimeOut()

{}



/*!

    \brief      Initialise the timer. It writes the current time of the day in the structure PreviousTime.

*/

//Initialize the timer

void TimeOut::InitTimer()

{

    gettimeofday(&PreviousTime, NULL);

}



/*!

    \brief      Returns the time elapsed since initialization.  It write the current time of the day in the structure CurrentTime.

                Then it returns the difference between CurrentTime and PreviousTime.

    \return     The number of microseconds elapsed since the functions InitTimer was called.

  */

//Return the elapsed time since initialization

unsigned long int TimeOut::ElapsedTime_ms()

{

    struct timeval CurrentTime;

    int sec,usec;

    gettimeofday(&CurrentTime, NULL);                                   // Get current time

    sec=CurrentTime.tv_sec-PreviousTime.tv_sec;                         // Compute the number of second elapsed since last call

    usec=CurrentTime.tv_usec-PreviousTime.tv_usec;                      // Compute

    if (usec<0) {                                                       // If the previous usec is higher than the current one

        usec=1000000-PreviousTime.tv_usec+CurrentTime.tv_usec;          // Recompute the microseonds

        sec--;                                                          // Substract one second

    }

    return sec*1000+usec/1000;

}


int main(int argc, char *argv[])
{
    int baudRate;
    int diagnosticMode = 0;
    /*
    if (diagnosticMode == 0) {
        if ( argc != 2 ) / * argc should be 2 for correct execution * /
        {
            / * We print argv[0] assuming it is the program name * /
            printf( "usage: %s <baud rate>\n", argv[0] );
            printf( "Where <baud rate> can be 9600, 19200, or 115200\n");
            return 0;
        }
        else {
            / *
            Check to make sure that the parameter is one of these: 9600, 19200, or 115200 
            * /
            baudRate = atoi(argv[1]);
            if ((baudRate == 9600 || baudRate == 19200 || baudRate == 115200) == false) {
                printf( "usage: %s <baud rate>\n", argv[0] );
                printf( "Where <baud rate> can be 9600, 19200, or 115200\n");
                return 0;
            }
        }
    }
    */

    serialib LS;                                                            // Object of the serialib class
    int Ret;                                                                // Used for return values
    char Buffer[128];

    // Open serial port
    Ret=LS.Open(DEVICE_PORT,115200);                                    // Open serial link at 115200 bauds
    //Ret=LS.Open(DEVICE_PORT,19200);                                      // Open serial link at 19200 bauds
    // Ret=LS.Open(DEVICE_PORT,9600);                                       // Open serial link at 9600 bauds
    printf ("Ret='%d'\n",Ret);        // ... display a message ...
    if (Ret!=1) {                                                           // If an error occured...
        printf ("Error while opening port. Permission problem ?\n");        // ... display a message ...
        return Ret;                                                         // ... quit the application
    }
    // printf ("Serial port opened successfully !\n");

    if (diagnosticMode == 1) {
        /*
            We're in diagnostic mode.
        */
        // Write the AT command on the serial port
        char userInput[80];
        int send;
        while (true) {
            puts("Send string options (a-f):");
            puts("a) V? - for Version.");
            puts("b) S? - for Status.");
            puts("c) L! - for displaying status ever interval.");
            puts("d) N! - Stopping the display of status ever interval.");
            puts("e) R? - to reset the system.");
            puts("f) Flush - this flushes out any buffers in the system.");
            puts("hasta) - exit the code.");
            scanf ("%s", userInput);
            
            // printf("userInput=%s",userInput);
            
            /* Loop through the array and change every character
             * to its uppercase equivilant */
            for(int i = 0; i < strlen(userInput); ++i)
            {
                userInput[i] = toupper(userInput[i]);
            }
            
            send = 0;
            if (!strcmp(userInput,"A")) {
                strcpy(userInput,"V?\n");
                send = 1;
            }
            else if (!strcmp(userInput,"B")) {
                strcpy(userInput,"S?\n");
                send = 1;
            }
            else if (!strcmp(userInput,"C")){
                strcpy(userInput,"L!\n");
                send = 1;
            }
            else if (!strcmp(userInput,"D")){
                strcpy(userInput,"N!\n");
                send = 1;
            }
            else if (!strcmp(userInput,"E")){
                strcpy(userInput,"R?\n");
                send = 1;
            }
            else if (!strcmp(userInput,"F")) {
                puts("Flushing out TS...");
                do {
                    // Read a string from the serial device
                    Ret=LS.ReadString(Buffer,'\n',128,500 /* 0.5 second*/ /*5000 5 sec test*/ );              // Read a maximum of 128 characters with a timeout of 0.5 seconds
                                                                                        // The final character of the string must be a line feed ('\n')
                    if (Ret>0)                                                              // If a string has been read from, print the string
                        printf ("String read from serial port : %s",Buffer);
                } while (Ret>0);
            }
            else if (!strcmp(userInput,"HASTA"))
                break;
            else 
                strcpy(userInput,"Not a valid input!!!");
                
            if (send == 1) {
            /*
                    The user wants a version
                */
                printf("Sending %s\n",userInput);
                Ret=LS.WriteString(userInput);                                             // Send the command on the serial port
                if (Ret!=1) {                                                           // If the writting operation failed ...
                    printf ("Error while writing data\n");                              // ... display a message ...
                    return Ret;                                                         // ... quit the application.
                }
                // printf ("Write operation is successful \n");
            
                // Read a string from the serial device
                Ret=LS.ReadString(Buffer,'\n',128,500 /* 0.5 second*/ /*5000 5 sec test*/ );              // Read a maximum of 128 characters with a timeout of 0.5 seconds
                                                                                    // The final character of the string must be a line feed ('\n')
                if (Ret>0)                                                              // If a string has been read from, print the string
                    printf ("String read from serial port : %s",Buffer);
                else
                    printf ("TimeOut reached. No data received !\n");                   // If not, print a message.
            
            }
        }

    }
    else {
        /*
            We're in non-diagnostic mode.
        */
        // printf("Initializing UART.\n");
        Ret=LS.WriteString("S?");                   // Get the status...
        if (Ret!=1) {                               // If the writting operation failed ...
            printf ("Error while writing data\n");  // ... display a message ...
            return Ret;                             // ... quit the application.
        }
    
        do {
            // Read a string from the serial device
            Ret=LS.ReadString(Buffer,'\n',128,500 /* 0.5 second*/ /*5000 5 sec test*/ );              // Read a maximum of 128 characters with a timeout of 0.5 seconds
                                                                                // The final character of the string must be a line feed ('\n')
            if (Ret>0)                                                              // If a string has been read from, print the string
                printf ("String read from serial port : %s",Buffer);
        } while (Ret>0);
        // puts("Done initializing UART.\n");
    }

    // Close the connection with the device

    LS.Close();

    return 0;
}
