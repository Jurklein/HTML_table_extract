CREATE OR REPLACE PACKAGE  ftp_interface AUTHID CURRENT_USER
AS
  /* Note: This package has been modified to add the dir and ls commands
   *
   *  PL/SQL FTP Client
   *
   *  Written by : Barry Chase (bsc7080mqc@mylxhq.com)
   *  http://www.mylxhq.com - Oracle Resource Portal
   *  March 2004
   *
   *
   *  OVERVIEW
   *  --------------------
   *  This package uses the standard packages UTL_FILE and UTL_TCP, along with LOBs to perform
   *  client-side FTP functionality (PUT, GET, RENAME, DELETE, DIR, LS) for files
   *  as defined in the World Wide Web Consortium's RFC 959 document - http://www.w3.org/Protocols/rfc959/
   *  The procedures and functions in this package allow single file transfer using
   *  standard TCP/IP connections.
   *
   *  LIMITATIONS
   *  --------------------
   *   Requires Oracle DB 9.2.x.x due to usage of UTL_FILE.READ_RAW and WRITE_RAW
   *
   *  USAGE
   *  --------------------
   *  Six primary functions are available for FTP - PUT, GET, RENAME, REMOVE, DIR, LS
   *
   *  The PUT and GET functions are included for convenience to FTP one file at a time.
   *  PUT and GET return true if the file is transferred successfully and false if it fails.
   *  REMOVE function deletes a file from a remote server.
   *  RENAME function renames a file on a remote server.
   *  DIR function fetches long-form directory listing from remote server
   *  LS function fetches short-form directory listing from remote server
   *
   *  EXAMPLE
   *  --------------------
   *  Below is an example of GET usage. Calling the other functions, would work similarly, but the PLSQL
   *  block could be customized in any number of ways. Such as looping through a set of parameters so that
   *  you could process multiple files, one after the other.
   *
   *  This example is the retrieval of an ASCII text file. Passing filetype of BINARY would retrieve a BINARY file
   *
   *
       DECLARE
          p_status                      VARCHAR2 (32000);
          p_error_msg                   VARCHAR2 (32000);
          p_elapsed_time                VARCHAR2 (100);
          p_remote_path                 VARCHAR2 (2000);
          p_local_path                  VARCHAR2 (2000);
          p_hostname                    VARCHAR2 (100);
          p_username                    VARCHAR2 (100);
          p_password                    VARCHAR2 (100);
          p_files                       VARCHAR2 (4000);
          p_bytes_trans                 NUMBER;
          p_trans_start                 DATE;
          p_trans_end                   DATE;
          lbok                          BOOLEAN;
          p_failed                      CHAR (1) := 'N';
       BEGIN
       -- Lets setup our output header columns
       --
       -- To process a file as a different name and for renaming a remote file, use the # symbol
       -- test.txt#test.txt20032801
       -- Would be used if you wanted to send the file test.txt but copy to remote server as test.txt20032801
       --   or to rename an existing remote file from test.txt to test.txt20032801
       
             DBMS_OUTPUT.put_line (   RPAD ('FILENAME', 40)
                                   || ' | '
                                   || RPAD ('STATUS', 15)
                                   || ' | '
                                   || RPAD ('BYTES', 15)
                                   || ' | '
                                   || RPAD ('START TIME', 25)
                                   || ' | '
                                   || RPAD ('END TIME', 25)
                                   || ' | '
                                   || 'ERROR MESSAGE');
             DBMS_OUTPUT.put_line (' ');
       --
       -- Let us GET an ASCII file
       --
             p_files                    := 'test.txt';
             lbok                       :=
                ftp_interface.get (p_localpath                   => 'local server path'
       ,                               p_filename                    => p_files
       ,                               p_remotepath                  => 'remote server path'
       ,                               p_username                    => 'ftp user account'
       ,                               p_password                    => 'ftp password'
       ,                               p_hostname                    => 'ftp server'
       ,                               v_status                      => p_status
       ,                               v_error_message               => p_error_msg
       ,                               n_bytes_transmitted           => p_bytes_trans
       ,                               d_trans_start                 => p_trans_start
       ,                               d_trans_end                   => p_trans_end
       ,                               p_port                        => 21
       ,                               p_filetype                  => 'ASCII'
                                      );

             IF lbok = TRUE
             THEN
                DBMS_OUTPUT.put_line (   RPAD (p_files, 40)
                                      || ' | '
                                      || RPAD (p_status, 15)
                                      || ' | '
                                      || RPAD (TO_CHAR (p_bytes_trans), 15)
                                      || ' | '
                                      || RPAD (TO_CHAR (p_trans_start
       ,                                                'YYYY-MM-DD HH:MI:SS')
       ,                                       25)
                                      || ' | '
                                      || RPAD (TO_CHAR (p_trans_end
       ,                                                'YYYY-MM-DD HH:MI:SS')
       ,                                       25)
                                      || ' | '
                                      || p_error_msg);

                IF p_status <> 'SUCCESS'
                THEN
                   p_failed                   := 'Y';
                END IF;
             ELSE
                DBMS_OUTPUT.put_line (p_error_msg);
                p_failed                   := 'Y';
             END IF;

          DBMS_OUTPUT.put_line (   'FTP PROCESS FAILED := '
                                || p_failed);
          DBMS_OUTPUT.put_line ('FINI');
       END;
   *
   *
   *
   *  CREDITS
   *  --------------------
   *
   *  This package was developed through about a 1 1/2 years of research. I have reviewed
   *  any number of partial and complete ftp solutions. None of them had everything that
   *  I desired. None of them worked exactly as hoped.
   *
   *  Good example is where the solution provided by Timothy Hall, which answered the question
   *  on how to read files from the filesystem into a LOB. His method worked, however it required
   *  DBA's to create a database directory. My current environment was somewhat resistant to
   *  an PLSQL FTP solution in the first place, let alone placing a dependency like this on it as
   *  well. Solution... leverage 9iR2 feature of UTL_FILE  (READ_RAW for binary and GET_LINE for ASCII)
   *  to read the files into their respective LOB format. Once in that format, then the rest of
   *  the routines would chain into each other correctly.
   *
   *  Additionally, this made this a useful generic process to retrieve from the filesystem into LOBs
   *  for usage in other procedures such as in mailing binary files
   *
   *  With this knowledge, I was able to implement binary support in the package where it had not
   *  previously been available.
   *
   *  Added MVS mainframe support as well, which was a limitation at first.
   *
   *  However, I still feel its important to give proper credit to those who have made their work public.
   *
   * --
   *  FTP_INTERFACE package created by Russ Johnson. rjohnson@braunconsult.com
   *   http://www.braunconsult.com
   *
   *  Much of the PL/SQL code in this package was based on Java code written by
   *  Bruce Blackshaw of Enterprise Distributed Technologies Ltd.  None of that code
   *  was copied, but the objects and methods greatly helped my understanding of the
   *  FTP Client process.
   *
   *  http://www.enterprisedt.com
   * --
   *
   * --
   *  Technical article wrriten by Dmitry Bouzolin. dbouzolin@yahoo.com
   *     http://www.quest-pipelines.com/newsletter-v3/0302_C.htm
   * --
   *
   * --
   *  FTP package created by Timothy Hall
   *  http://www.oracle-base.com/articles/9i/FTPFromPLSQL9i.php
   * --
   *
   * --
   *  FTP command reference
   *   http://cr.yp.to/ftp.html
   * --
   *
   * --
   *  Ask Tom - Oracle Forum
   *   http://asktom.oracle.com
   * --
   *
   * --
   *  The W3C's RFC 959 that describes the FTP process.
   *  http://www.w3c.org
   * --
   *
   *
   *VERSION HISTORY
   *  --------------------
   *  1.0     11/19/2002    Unit-tested single and multiple transfers between disparate hosts.
   *  1.0      01/18/2003   Began testing code as proof of concept under 8i.
   *                        As delivered the code did not work correctly for our 8i environment
   *  1.1     03/03/2003    Left package on the shelf to gather dust for awhile.
   *                        Modified login code. Kept failing for some reason.
   *                        Removed multiple file support. Couldn't seem to make it work right.
   *                  Added time_out setting which terminates session if it exceeds 4 minutes
   *                  Added functionality for remove and rename, and for sending as different filename
   *
   *                          -- To process a file as a different name use the # symbol
   *                          -- test.txt#test.txt20032801
   *                          -- Would be used if you wanted to send the file test.txt
   *                              but copy to remote server as test.txt20032801
   *
   *  2.0      03/01/2004   Upgraded script to support Oracle 9.2.x.x features
   *                        Added binary support
   *                        Added MVS mainframe support
   *  2.1      05/05/2006   Added dir and ls functionality
   *
   */
--
--
--
-- Declarations
--
-- /* UTL_TCP Connection */
   u_data_con                    UTL_TCP.connection;
   u_ctrl_con                    UTL_TCP.connection;
   /* BLOB  placeholders */
   g_data_b                      BLOB;
   /*
    * Timeout
    *
   */
   tx_timeout                    PLS_INTEGER := 240;
                                                  -- 240 seconds := 4 minutes
   /*
    * Mainframe
   */
   mainframe_connection          BOOLEAN := FALSE;
   mainframe_cmd                 VARCHAR2 (2000);
   /**
    * Exceptions
    *
    */
   ctrl_exception                EXCEPTION;
   data_exception                EXCEPTION;
   /**
    * Constants - FTP valid response codes
    *
    */
   connect_code         CONSTANT PLS_INTEGER := 220;
   user_code            CONSTANT PLS_INTEGER := 331;
   login_code           CONSTANT PLS_INTEGER := 230;
   pwd_code             CONSTANT PLS_INTEGER := 257;
   pasv_code            CONSTANT PLS_INTEGER := 227;
   cwd_code             CONSTANT PLS_INTEGER := 250;
   tsfr_start_code1     CONSTANT PLS_INTEGER := 125;
   tsfr_start_code2     CONSTANT PLS_INTEGER := 150;
   tsfr_end_code        CONSTANT PLS_INTEGER := 226;
   tsfr_end_code_mf     CONSTANT PLS_INTEGER := 250;
-- Had to add this code (tsfr_end_code_mf) because our mainframe success code was 250 and not 226 --
   quit_code            CONSTANT PLS_INTEGER := 221;
   syst_code            CONSTANT PLS_INTEGER := 215;
   type_code            CONSTANT PLS_INTEGER := 200;
   delete_code          CONSTANT PLS_INTEGER := 250;
   rnfr_code            CONSTANT PLS_INTEGER := 350;
   rnto_code            CONSTANT PLS_INTEGER := 250;
   site_code            CONSTANT PLS_INTEGER := 200;

   /**
    * FTP File record datatype
    *
    * Elements:
    * localpath - full directory name in which the local file resides or will reside
    *           Windows: 'd:\oracle\utl_file'
    *           UNIX: '/home/oracle/utl_file'
    * filename - filename and extension for the file to be received or sent
    * remotepath - full directory name in which the local file will be sent or the
    *            remote file exists.  Should be in UNIX format regardless of FTP server - '/one/two/three'
    * filetype - 'ASCII' or 'BINARY'
    * transfer_mode - 'PUT', 'GET', 'REMOVE', 'RENAME', 'DIR', 'LS'
    * status - status of the transfer.  'ERROR' or 'SUCCESS'
    * error_message - meaningful (hopefully) error message explaining the reason for failure
    * bytes_transmitted - how many bytes were sent/received
    * trans_start - date/time the transmission started
    * trans_end - date/time the transmission ended
    *
    */
   TYPE r_ftp_rec IS RECORD (
      localpath                     VARCHAR2 (255)
,     filename                      VARCHAR2 (255)
,     remotepath                    VARCHAR2 (255)
,     filetype                      VARCHAR2 (20)
,     transfer_mode                 VARCHAR2 (30)
,     status                        VARCHAR2 (40)
,     error_message                 VARCHAR2 (255)
,     bytes_transmitted             NUMBER
,     trans_start                   DATE
,     trans_end                     DATE
   );

   /**
    * FTP File Table - used to store many files for transfer
    *
    */
   TYPE t_ftp_rec IS TABLE OF r_ftp_rec
      INDEX BY BINARY_INTEGER;

   /**
    * Internal convenience procedure for creating passive host IP address
    * and port number.
    *
    */
   PROCEDURE create_pasv (
      p_pasv_cmd                 IN       VARCHAR2
,     p_pasv_host                OUT      VARCHAR2
,     p_pasv_port                OUT      NUMBER
   );

   /**
    * Function used to validate FTP server responses based on the
    * code passed in p_code.  Reads single or multi-line responses.
    *
    */
   FUNCTION validate_reply (
      p_ctrl_con                 IN OUT   UTL_TCP.connection
,     p_code                     IN       PLS_INTEGER
,     p_reply                    OUT      VARCHAR2
   )
      RETURN BOOLEAN;

   /**
    * Function used to validate FTP server responses based on the
    * code passed in p_code.  Reads single or multi-line responses.
    * Overloaded because some responses can have 2 valid codes.
    *
    */
   FUNCTION validate_reply (
      p_ctrl_con                 IN OUT   UTL_TCP.connection
,     p_code1                    IN       PLS_INTEGER
,     p_code2                    IN       PLS_INTEGER
,     p_reply                    OUT      VARCHAR2
   )
      RETURN BOOLEAN;

   /**
    * Procedure that handles the actual data transfer.  Meant
    * for internal package use.  Returns information about the
    * actual transfer.
    *
   * For binary files, I have performed testing with zip files only.
   *
    */
   PROCEDURE transfer_data (
      u_ctrl_connection          IN OUT   UTL_TCP.connection
,     p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_filetype                 IN       VARCHAR2
,     p_pasv_host                IN       VARCHAR2
,     p_pasv_port                IN       PLS_INTEGER
,     p_transfer_mode            IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
   );

   /**
    * Function to handle FTP of files.
    * Returns TRUE if no batch-level errors occur.
    * Returns FALSE if a batch-level error occurs.
    *
    * Parameters:
    *
    * p_error_msg - error message for batch level errors
    * p_files - FTP_INTERFACE.t_ftp_rec table type.  Accepts
    *           list of files to be transferred
    *           returns the table updated with transfer status, error message,
    *           bytes_transmitted, transmission start date/time and transmission end
    *           date/time
    * p_username - username for FTP server
    * p_password - password for FTP server
    * p_hostname - hostname or IP address of server Ex: 'ftp.oracle.com' or '127.0.0.1'
    * p_port - port number to connect on.  FTP is usually on 21, but this may be overridden
    *          if the server is configured differently.
    *
    */
   FUNCTION ftp_files_stage (
      p_error_msg                OUT      VARCHAR2
,     p_files                    IN OUT   t_ftp_rec
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     p_port                     IN       PLS_INTEGER DEFAULT 21
   )
      RETURN BOOLEAN;

   /* Retrieves local binary file from database server.
    * using DBMS_LOB commands and stores into BLOB
    *
    * return BLOB
   */
   FUNCTION get_local_binary_data (
      p_dir                      IN       VARCHAR2
,     p_file                     IN       VARCHAR2
   )
      RETURN BLOB;

   /* Retrieves remote binary file from ftp server.
    * using UTL_TCP.READ_RAW and stores into BLOB
    *
    * Requires existing TCP connection
    * return BLOB
   */
   FUNCTION get_remote_binary_data (
      u_ctrl_connection          IN OUT   UTL_TCP.connection
   )
      RETURN BLOB;

   /* Writes local binary file to database server.
    * using UTL_FILE.PUT_RAW
    *
    * requires BLOB input
    *
   */
   PROCEDURE put_local_binary_data (
      p_data                     IN       BLOB
,     p_dir                      IN       VARCHAR2
,     p_file                     IN       VARCHAR2
   );

   /* Writes remote binary file to ftp server.
    * using UTL_TCP.WRITE_RAW
    *
    * Requires existing TCP connection
    * requires BLOB input
    *
   */
   PROCEDURE put_remote_binary_data (
      u_ctrl_connection          IN OUT   UTL_TCP.connection
,     p_data                     IN       BLOB
   );

   /**
    * Convenience function for single-file PUT
    *
    * Parameters:
    * p_localpath - full directory name in which the local file resides or will reside
    *           Windows: 'd:\oracle\utl_file'
    *           UNIX: '/home/oracle/utl_file'
    * p_filename - filename and extension for the file to be received or sent
    *          changing the filename for the PUT or GET is currently not allowed
    *          Examples: 'myfile.dat' 'myfile20021119.xml'
    * p_remotepath - full directory name in which the local file will be sent or the
    *            remote file exists.  Should be in UNIX format regardless of FTP server - '/one/two/three'
    * p_username - username for FTP server
    * p_password - password for FTP server
    * p_hostname - FTP server IP address or host name Ex: 'ftp.oracle.com' or '127.0.0.1'
    * v_status - status of the transfer.  'ERROR' or 'SUCCESS'
    * v_error_message - meaningful (hopefully) error message explaining the reason for failure
    * n_bytes_transmitted - how many bytes were sent/received
    * d_trans_start - date/time the transmission started
    * d_trans_end - date/time the transmission ended
    * p_port - port number to connect to, default is 21
    * p_filetype - Default to ASCII but optionally can be BINARY
             BINARY requires the creation of a Database Directory which points to real directory
             path on your database server. It is recommended that you only use ZIP files when
             attempting to process a BINARY file.
    * p_mainframe_ftp - Default FALSE. If target server is Mainframe MVS, must be TRUE.
   * p_mainframe_cmd - If Mainframe parm is TRUE, then this must have a value
   *                 For file transfers this would be the site command to define file layout
    */
   FUNCTION put (
      p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'ASCII'
,     p_mainframe_ftp            IN       BOOLEAN DEFAULT FALSE
,     p_mainframe_cmd            IN       VARCHAR2 DEFAULT NULL
   )
      RETURN BOOLEAN;

   /**
    * Convenience function for single-file GET
    *
    * Parameters:
    * p_localpath - full directory name in which the local file resides or will reside
    *           Windows: 'd:\oracle\utl_file'
    *           UNIX: '/home/oracle/utl_file'
    * p_filename - filename and extension for the file to be received or sent
    *          changing the filename for the PUT or GET is currently not allowed
    *          Examples: 'myfile.dat' 'myfile20021119.xml'
    * p_remotepath - full directory name in which the local file will be sent or the
    *            remote file exists.  Should be in UNIX format regardless of FTP server - '/one/two/three'
    * p_username - username for FTP server
    * p_password - password for FTP server
    * p_hostname - FTP server IP address or host name Ex: 'ftp.oracle.com' or '127.0.0.1'
    * v_status - status of the transfer.  'ERROR' or 'SUCCESS'
    * v_error_message - meaningful (hopefully) error message explaining the reason for failure
    * n_bytes_transmitted - how many bytes were sent/received
    * d_trans_start - date/time the transmission started
    * d_trans_end - date/time the transmission ended
    * p_port - port number to connect to, default is 21
    * p_filetype - Default to ASCII but optionally can be BINARY
             BINARY requires the creation of a Database Directory which points to real directory
             path on your database server. It is recommended that you only use ZIP files when
             attempting to process a BINARY file.
    * p_mainframe_ftp - Default FALSE. If target server is Mainframe MVS, must be TRUE.
    * p_mainframe_cmd - If Mainframe parm is TRUE, then this must have a value
    *                 For file transfers this would be the site command to define file layout
    */
   FUNCTION get (
      p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'ASCII'
,     p_mainframe_ftp            IN       BOOLEAN DEFAULT FALSE
,     p_mainframe_cmd            IN       VARCHAR2 DEFAULT NULL
   )
      RETURN BOOLEAN;

    /**
    * Convenience function for single-file DELETE
    *
    * Parameters:
    * p_localpath - Value will be NULL as it does not apply
    * p_filename - filename and extension for the file to be deleted on remote server
    * p_remotepath - full directory name in which the remote file exists.
   * Should be in UNIX format regardless of FTP server - '/one/two/three'
    * p_username - username for FTP server
    * p_password - password for FTP server
    * p_hostname - FTP server IP address or host name Ex: 'ftp.oracle.com' or '127.0.0.1'
    * v_status - status of the transfer.  'ERROR' or 'SUCCESS'
    * v_error_message - meaningful (hopefully) error message explaining the reason for failure
    * n_bytes_transmitted - how many bytes were sent/received
    * d_trans_start - date/time the transmission started
    * d_trans_end - date/time the transmission ended
    * p_port - port number to connect to, default is 21
    * p_filetype - Default to BINARY. Value is ignored during process.
    * p_mainframe_connection - Default FALSE. If target server is Mainframe MVS, must be TRUE.
    */
   FUNCTION remove (
      p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'BINARY'
,     p_mainframe_connection     IN       BOOLEAN DEFAULT FALSE
   )
      RETURN BOOLEAN;

   /**
    * Convenience function for single-file  REN
    *
    * Parameters:
    * p_localpath - Value will be NULL as it does not apply
    * p_filename - Concatenated value of filename.ext | new_filename.ext on remote server
    * p_remotepath - full directory name in which the remote file exists.
   * Should be in UNIX format regardless of FTP server - '/one/two/three'
    * p_username - username for FTP server
    * p_password - password for FTP server
    * p_hostname - FTP server IP address or host name Ex: 'ftp.oracle.com' or '127.0.0.1'
    * v_status - status of the transfer.  'ERROR' or 'SUCCESS'
    * v_error_message - meaningful (hopefully) error message explaining the reason for failure
    * n_bytes_transmitted - how many bytes were sent/received
    * d_trans_start - date/time the transmission started
    * d_trans_end - date/time the transmission ended
    * p_port - port number to connect to, default is 21
    * p_filetype - Default to BINARY. Value is ignored during process.
    * p_mainframe_connection - Default FALSE. If target server is Mainframe MVS, must be TRUE.
    */
   FUNCTION ren (
      p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'BINARY'
,     p_mainframe_connection     IN       BOOLEAN DEFAULT FALSE
   )
      RETURN BOOLEAN;

   /**
    * Convenience function for single-file  VERIFY_SERVER
    *
    * Parameters:
    * p_remotepath - full directory name in which the remote file exists.
    *              Should be in UNIX format regardless of FTP server - '/one/two/three'
    * p_username - username for FTP server
    * p_password - password for FTP server
    * p_hostname - FTP server IP address or host name Ex: 'ftp.oracle.com' or '127.0.0.1'
    * v_status   - status of the transfer.  'ERROR' or 'SUCCESS'
    * v_error_message - meaningful (hopefully) error message explaining the reason for failure
    * p_port - port number to connect to, default is 21
    * p_filetype - Default to BINARY. Value is ignored during process.
    * p_mainframe_connection - Default FALSE. If target server is Mainframe MVS, must be TRUE.
    */
   FUNCTION verify_server (
      p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'BINARY'
,     p_mainframe_connection     IN       BOOLEAN DEFAULT FALSE
   )
      RETURN BOOLEAN;
      
    /**
    * Convenience function for DIR
    *
    * Parameters:
    * p_localpath - full directory name in which the local file resides or will reside
    *           Windows: 'd:\oracle\utl_file'
    *           UNIX: '/home/oracle/utl_file'
    * p_filename - filename and extension for the file to be written locally, containing directory
    *          contents in long form. (Permissions,Ownership,FileSize,FileDate,FileName)
    * p_remotepath - full directory name to get a list of files from
    *            Should be in UNIX format regardless of FTP server - '/one/two/three'
    * p_username - username for FTP server
    * p_password - password for FTP server
    * p_hostname - FTP server IP address or host name Ex: '
ftp.oracle.com' or '127.0.0.1'
    * v_status - status of the transfer.  'ERROR' or 'SUCCESS'
    * v_error_message - meaningful (hopefully) error message explaining the reason for failure
    * n_bytes_transmitted - how many bytes were sent/received
    * d_trans_start - date/time the transmission started
    * d_trans_end - date/time the transmission ended
    * p_port - port number to connect to, default is 21
    * p_filetype - Default to ASCII but optionally can be BINARY
             BINARY requires the creation of a Database Directory which points to real directory
             path on your database server. It is recommended that you only use ZIP files when
             attempting to process a BINARY file.
    * p_mainframe_ftp - Default FALSE. If target server is Mainframe MVS, must be TRUE.
    * p_mainframe_cmd - If Mainframe parm is TRUE, then this must have a value
    *                 For file transfers this would be the site command to define file layout
    */
      
  FUNCTION dir (
      p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'ASCII'
,     p_mainframe_ftp            IN       BOOLEAN DEFAULT FALSE
,     p_mainframe_cmd            IN       VARCHAR2 DEFAULT NULL
   )
      RETURN BOOLEAN;
      
        /**
    * Convenience function for LS
    *
    * Parameters:
    * p_localpath - full directory name in which the local file resides or will reside
    *           Windows: 'd:\oracle\utl_file'
    *           UNIX: '/home/oracle/utl_file'
    * p_filename - filename and extension for the file to be written locally, containing directory
    *          contents in short form (Filenames only)
    * p_remotepath - full directory name to get a list of files from
    *            Should be in UNIX format regardless of FTP server - '/one/two/three'
    * p_username - username for FTP server
    * p_password - password for FTP server
    * p_hostname - FTP server IP address or host name Ex: 'ftp.oracle.com' or '127.0.0.1'
    * v_status - status of the transfer.  'ERROR' or 'SUCCESS'
    * v_error_message - meaningful (hopefully) error message explaining the reason for failure
    * n_bytes_transmitted - how many bytes were sent/received
    * d_trans_start - date/time the transmission started
    * d_trans_end - date/time the transmission ended
    * p_port - port number to connect to, default is 21
    * p_filetype - Default to ASCII but optionally can be BINARY
             BINARY requires the creation of a Database Directory which points to real directory
             path on your database server. It is recommended that you only use ZIP files when
             attempting to process a BINARY file.
    * p_mainframe_ftp - Default FALSE. If target server is Mainframe MVS, must be TRUE.
    * p_mainframe_cmd - If Mainframe parm is TRUE, then this must have a value
    *                 For file transfers this would be the site command to define file layout
    */
      
  FUNCTION ls (
      p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'ASCII'
,     p_mainframe_ftp            IN       BOOLEAN DEFAULT FALSE
,     p_mainframe_cmd            IN       VARCHAR2 DEFAULT NULL
   )
      RETURN BOOLEAN;
END;
/
CREATE OR REPLACE 
PACKAGE BODY  ftp_interface
AS
   TYPE tstringtable IS TABLE OF VARCHAR2 (2000);

   TYPE tserverreply IS RECORD (
      rpt                           CHAR
,     code                          VARCHAR2 (3)
,     MESSAGE                       VARCHAR2 (256)
   );

   TYPE tserverreplya IS TABLE OF tserverreply;

   TYPE tconnectinfo IS RECORD (
      ip                            VARCHAR2 (22)
,     port                          PLS_INTEGER
   );

   FUNCTION writecommand (
      a_conn                     IN       UTL_TCP.connection
,     a_command                  IN       VARCHAR2
   )
      RETURN tserverreplya
   IS
      v_conn                        UTL_TCP.connection;
      v_str                         VARCHAR2 (500);
      v_bytes_written               NUMBER;
      v_reply                       tserverreplya;
   BEGIN
      v_reply                    := tserverreplya ();
      v_conn                     := a_conn;

      IF a_command IS NOT NULL
      THEN
         v_bytes_written            := UTL_TCP.write_line (v_conn, a_command);
      END IF;

      v_conn                     := a_conn;

      WHILE 1 = 1
      LOOP
         v_str                      := UTL_TCP.get_line (v_conn, TRUE);
         v_reply.EXTEND;
         v_reply (v_reply.COUNT).code := SUBSTR (v_str
,                                                1
,                                                3
                                                );
         v_reply (v_reply.COUNT).rpt := SUBSTR (v_str
,                                               4
,                                               1
                                               );
         v_reply (v_reply.COUNT).MESSAGE := SUBSTR (v_str, 5);

         IF v_reply (v_reply.COUNT).rpt = ' '
         THEN
            EXIT;
         END IF;
      END LOOP;

      IF SUBSTR (v_reply (v_reply.COUNT).code
,                1
,                1
                ) = '5'
      THEN
         raise_application_error (-20000
,                                    'WriteCommand: '
                                  || v_str
,                                 TRUE
                                 );
      END IF;

      RETURN v_reply;
   END;

   FUNCTION login (
      a_site_in                  IN       VARCHAR2
,     a_port_in                  IN       VARCHAR2
,     a_user_name                IN       VARCHAR2
,     a_user_pass                IN       VARCHAR2
   )
      RETURN UTL_TCP.connection
   IS
      v_conn                        UTL_TCP.connection;
      v_reply                       tserverreplya;
   BEGIN
      v_conn                     :=
         UTL_TCP.open_connection (remote_host                   => a_site_in
,                                 remote_port                   => a_port_in
,                                 tx_timeout                    => tx_timeout
                                 );
      v_reply                    := writecommand (v_conn, NULL);

      IF v_reply (v_reply.COUNT).code <> '220'
      THEN
         UTL_TCP.close_all_connections;
         raise_application_error (-20001
,                                    'Login: '
                                  || v_reply (v_reply.COUNT).code
                                  || ' '
                                  || v_reply (v_reply.COUNT).MESSAGE
,                                 TRUE
                                 );
         RETURN v_conn;
      END IF;

      v_reply                    :=
                                 writecommand (v_conn, 'USER '
                                                || a_user_name);

      IF SUBSTR (v_reply (v_reply.COUNT).code
,                1
,                1
                ) = '5'
      THEN
         UTL_TCP.close_all_connections;
         raise_application_error (-20000
,                                    'Login: '
                                  || v_reply (v_reply.COUNT).code
                                  || ' '
                                  || v_reply (v_reply.COUNT).MESSAGE
,                                 TRUE
                                 );
         RETURN v_conn;
      END IF;

      IF v_reply (v_reply.COUNT).code <> '331'
      THEN
         UTL_TCP.close_all_connections;
         raise_application_error (-20001
,                                    'Login: '
                                  || v_reply (v_reply.COUNT).code
                                  || ' '
                                  || v_reply (v_reply.COUNT).MESSAGE
,                                 TRUE
                                 );
         RETURN v_conn;
      END IF;

      v_reply                    :=
                                 writecommand (v_conn, 'PASS '
                                                || a_user_pass);

      IF SUBSTR (v_reply (v_reply.COUNT).code
,                1
,                1
                ) = '5'
      THEN
         UTL_TCP.close_all_connections;
         raise_application_error (-20000
,                                    'Login: '
                                  || v_reply (v_reply.COUNT).code
                                  || ' '
                                  || v_reply (v_reply.COUNT).MESSAGE
,                                 TRUE
                                 );
         RETURN v_conn;
      END IF;

      IF v_reply (v_reply.COUNT).code <> '230'
      THEN
         UTL_TCP.close_all_connections;
         raise_application_error (-20001
,                                    'Login: '
                                  || v_reply (v_reply.COUNT).code
                                  || ' '
                                  || v_reply (v_reply.COUNT).MESSAGE
,                                 TRUE
                                 );
         RETURN v_conn;
      END IF;

      RETURN v_conn;
   END;

   /* Display Output. Displays DBMS_OUTPUT in chunks so we don't bust the 255 limit by accident */
   PROCEDURE print_output (
      p_message                  IN       VARCHAR2
   )
   IS
   BEGIN
      DBMS_OUTPUT.put_line (SUBSTR (p_message
,                                   1
,                                   250
                                   ));

      IF LENGTH (p_message) > 250
      THEN
         DBMS_OUTPUT.put_line (SUBSTR (p_message
,                                      251
,                                      500
                                      ));
      END IF;

      IF LENGTH (p_message) > 500
      THEN
         DBMS_OUTPUT.put_line (SUBSTR (p_message
,                                      501
,                                      750
                                      ));
      END IF;

      IF LENGTH (p_message) > 750
      THEN
         DBMS_OUTPUT.put_line (SUBSTR (p_message
,                                      751
,                                      1000
                                      ));
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;             -- Ignore errors... protect buffer overflow's etc.
   END print_output;

   /*****************************************************************************
   **  Create the passive host IP and port  NUMBER to connect to
   **
   *****************************************************************************/
   PROCEDURE create_pasv (
      p_pasv_cmd                 IN       VARCHAR2
,     p_pasv_host                OUT      VARCHAR2
,     p_pasv_port                OUT      NUMBER
   )
   IS
      v_pasv_cmd                    VARCHAR2 (30) := p_pasv_cmd;
      --Host and port to connect to for data transfer
      n_port_dec                    NUMBER;
      n_port_add                    NUMBER;
   BEGIN
      p_pasv_host                :=
         REPLACE (SUBSTR (v_pasv_cmd
,                         1
,                           INSTR (v_pasv_cmd
,                                  ','
,                                  1
,                                  4
                                  )
                          - 1
                         )
,                 ','
,                 '.'
                 );
      n_port_dec                 :=
         TO_NUMBER (SUBSTR (v_pasv_cmd
,                             INSTR (v_pasv_cmd
,                                    ','
,                                    1
,                                    4
                                    )
                            + 1
,                           (  INSTR (v_pasv_cmd
,                                     ','
,                                     1
,                                     5
                                     )
                             - (  INSTR (v_pasv_cmd
,                                        ','
,                                        1
,                                        4
                                        )
                                + 1)
                            )
                           ));
      n_port_add                 :=
         TO_NUMBER (SUBSTR (v_pasv_cmd
,                             INSTR (v_pasv_cmd
,                                    ','
,                                    1
,                                    5
                                    )
                            + 1
,                             LENGTH (v_pasv_cmd)
                            - INSTR (v_pasv_cmd
,                                    ','
,                                    1
,                                    5
                                    )
                           ));
      p_pasv_port                :=   (  n_port_dec
                                       * 256)
                                    + n_port_add;
--       print_output (   'p_pasv_host= '
--                             || p_pasv_host);
--       print_output (   'n_port_dec= '
--                             || n_port_dec);
--       print_output (   'n_port_add= '
--                             || n_port_add);
--       print_output (   'p_pasv_port= '
--                             || p_pasv_port);
   EXCEPTION
      WHEN OTHERS
      THEN
         --print_output(SQLERRM);
         RAISE;
   END create_pasv;

   /*****************************************************************************
   **  Read a single or multi-line reply from the FTP server and VALIDATE
   **  it against the code passed in p_code.
   **
   **  Return TRUE if reply code matches p_code, FALSE if it doesn't or error
   **  occurs
   **
   **  Send full server response back to calling procedure
   *****************************************************************************/
   FUNCTION validate_reply (
      p_ctrl_con                 IN OUT   UTL_TCP.connection
,     p_code                     IN       PLS_INTEGER
,     p_reply                    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      n_code                        VARCHAR2 (3) := p_code;
      n_byte_count                  PLS_INTEGER;
      v_msg                         VARCHAR2 (255);
      n_line_count                  PLS_INTEGER := 0;
   BEGIN
      LOOP
         v_msg                      := UTL_TCP.get_line (p_ctrl_con);
         n_line_count               :=   n_line_count
                                       + 1;

         IF n_line_count = 1
         THEN
            p_reply                    := v_msg;
         ELSE
            p_reply                    :=    p_reply
                                          || SUBSTR (v_msg, 4);
         END IF;

         EXIT WHEN INSTR (v_msg
,                         '-'
,                         1
,                         1
                         ) <> 4;
      END LOOP;

--      print_output('n_code := ' || n_code);
--      print_output('p_reply := ' || TO_NUMBER (SUBSTR (p_reply, 1, 3)));
      IF TO_NUMBER (SUBSTR (p_reply
,                           1
,                           3
                           )) = n_code
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_reply                    := SQLERRM;
         RETURN FALSE;
   END validate_reply;

   /*****************************************************************************
   **  Reads a single or multi-line reply from the FTP server
   **
   **  Return TRUE if reply code matches p_code1 or p_code2,
   **  FALSE if it doesn't or error occurs
   **
   **  Send full server response back to calling procedure
   *****************************************************************************/
   FUNCTION validate_reply (
      p_ctrl_con                 IN OUT   UTL_TCP.connection
,     p_code1                    IN       PLS_INTEGER
,     p_code2                    IN       PLS_INTEGER
,     p_reply                    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_code1                       VARCHAR2 (3) := TO_CHAR (p_code1);
      v_code2                       VARCHAR2 (3) := TO_CHAR (p_code2);
      v_msg                         VARCHAR2 (255);
      n_line_count                  PLS_INTEGER := 0;
   BEGIN
      LOOP
         v_msg                      := UTL_TCP.get_line (p_ctrl_con);
         n_line_count               :=   n_line_count
                                       + 1;

         IF n_line_count = 1
         THEN
            p_reply                    := v_msg;
         ELSE
            p_reply                    :=    p_reply
                                          || SUBSTR (v_msg, 4);
         END IF;

         EXIT WHEN INSTR (v_msg
,                         '-'
,                         1
,                         1
                         ) <> 4;
      END LOOP;

      IF TO_NUMBER (SUBSTR (p_reply
,                           1
,                           3
                           )) IN (v_code1, v_code2)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_reply                    := SQLERRM;
         RETURN FALSE;
   END validate_reply;

   /*****************************************************************************
   **  Handles actual data transfer.  Responds with status, error message, and
   **  transfer statistics.
   **
   **  Potential errors could be with connection or file i/o
   **
   *****************************************************************************/
   PROCEDURE transfer_data (
      u_ctrl_connection          IN OUT   UTL_TCP.connection
,     p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_filetype                 IN       VARCHAR2
,     p_pasv_host                IN       VARCHAR2
,     p_pasv_port                IN       PLS_INTEGER
,     p_transfer_mode            IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
   )
   IS
      l_amount                      PLS_INTEGER;
      u_filehandle                  UTL_FILE.file_type;
      v_tsfr_mode                   VARCHAR2 (30) := p_transfer_mode;
      v_mode                        VARCHAR2 (1);
      v_tsfr_cmd                    VARCHAR2 (10);
      v_buffer                      VARCHAR2 (32767);
      v_localpath                   VARCHAR2 (255) := p_localpath;
      v_filename                    VARCHAR2 (255) := p_filename;
      v_filenamefr                  VARCHAR2 (255) := p_filename;
      v_filenameto                  VARCHAR2 (255) := p_filename;
      v_host                        VARCHAR2 (20) := p_pasv_host;
      n_port                        PLS_INTEGER := p_pasv_port;
      n_bytes                       NUMBER;
      v_msg                         VARCHAR2 (255);
      v_reply                       VARCHAR2 (1000);
      v_err_status                  VARCHAR2 (20) := 'ERROR';
      v_database_directory          VARCHAR2 (100);
      p_data_clob                   CLOB;
      p_data_blob                   BLOB;
   BEGIN
/** Initialize some of our OUT variables **/
      v_status                   := 'SUCCESS';
      v_error_message            := ' ';
      n_bytes_transmitted        := 0;

      IF NVL (INSTR (v_filename, '#'), 0) = 0
      THEN
         v_filenamefr               := v_filename;
         v_filenameto               := v_filename;
      ELSE
         v_filenamefr               :=
            LTRIM (RTRIM (SUBSTR (v_filename
,                                 1
,                                   INSTR (v_filename, '#')
                                  - 1
                                 )));
         v_filenameto               :=
               LTRIM (RTRIM (SUBSTR (v_filename, INSTR (v_filename, '#')
                                      + 1)));
      END IF;

      IF    UPPER (v_tsfr_mode) = 'PUT'
      THEN
         v_mode                     := 'r';
         v_tsfr_cmd                 := 'STOR ';
      ELSIF UPPER (v_tsfr_mode) = 'GET'
      THEN
         v_mode                     := 'w';
         v_tsfr_cmd                 := 'RETR ';
      ELSIF UPPER (v_tsfr_mode) = 'LIST'
      THEN
         v_mode                     := 'w';
         v_tsfr_cmd                 := 'LIST ';
      ELSIF UPPER (v_tsfr_mode) = 'NLST'
      THEN
         v_mode                     := 'w';
         v_tsfr_cmd                 := 'NLST ';
      ELSIF UPPER (v_tsfr_mode) = 'DELE'
      THEN
         v_mode                     := 'd';
         v_tsfr_cmd                 := 'DELE ';
      ELSIF UPPER (v_tsfr_mode) = 'RNFR'
      THEN
         v_mode                     := 'm';
         v_tsfr_cmd                 := 'RNFR'; --was 'RNFR ', but its not consistent with using v_tsfr_cmd later on
      END IF;

/** Open data connection on Passive host and port **/
      u_data_con                 :=
         UTL_TCP.open_connection (remote_host                   => v_host
,                                 remote_port                   => n_port
,                                 tx_timeout                    => tx_timeout
                                 );
-- v_mode is used for determining local actions
/* FILE STUFF */
      IF v_mode IN ('r')
      THEN
         IF p_filetype = 'BINARY'
         THEN
/* Read file into LOB for transferring */
            p_data_blob                :=
               get_local_binary_data (p_dir                         => v_localpath
,                                     p_file                        => v_filenamefr);
         ELSE
/** Open the local file to read and transfer data **/
            u_filehandle               :=
                           UTL_FILE.fopen (v_localpath
,                                          v_filenamefr
,                                          v_mode
                                          );
         END IF;
      ELSIF v_mode IN ('w')
      THEN
/** Open the local file to write and transfer data **/
         u_filehandle               :=
                           UTL_FILE.fopen (v_localpath
,                                          v_filenameto
,                                          v_mode
                                          );
      END IF;

-- v_tsfr_cmd is used for determining remote actions
      IF UPPER (v_tsfr_cmd) = 'DELE'
         THEN
         /** Send the DELE command to tell the server we're going to delete a file **/
         IF mainframe_connection
         THEN
            n_bytes                    :=
               UTL_TCP.write_line (u_ctrl_connection
,                                     v_tsfr_cmd
                                   || ''''
                                   || v_filenamefr
                                   || '''');
         ELSE
            n_bytes                    :=
               UTL_TCP.write_line (u_ctrl_connection
,                                     v_tsfr_cmd
                                   || v_filenamefr);
         END IF;
      ELSIF UPPER (v_tsfr_cmd) = 'RNFR'
         THEN
         /** Send the RNFR command to tell the server we're going to rename a file **/
         IF mainframe_connection
         THEN
            n_bytes                    :=
               UTL_TCP.write_line (u_ctrl_con
,                                     'RNFR ' 
                                   || ''''
                                   || v_filenamefr
                                   || '''');
--
            IF validate_reply (u_ctrl_con
,                              rnfr_code
,                              v_reply
                              ) = FALSE
            THEN
               RAISE ctrl_exception;
            END IF;
         ELSE
            n_bytes                    :=
                     UTL_TCP.write_line (u_ctrl_con, 'RNFR ' 
                                          || v_filenamefr);

--
            IF validate_reply (u_ctrl_con
,                              rnfr_code
,                              v_reply
                              ) = FALSE
            THEN
               RAISE ctrl_exception;
            END IF;
         END IF;
--
         /** Send the RNTO command to tell the server we're going to rename a file to this name**/
         IF mainframe_connection
         THEN
            n_bytes                    :=
               UTL_TCP.write_line (u_ctrl_con
,                                     'RNTO '
                                   || ''''
                                   || v_filenameto
                                   || '''');
         ELSE
            n_bytes                    :=
                     UTL_TCP.write_line (u_ctrl_con, 'RNTO '
                                          || v_filenameto);
         END IF;
      ELSIF UPPER (v_tsfr_mode) = 'RETR'
         THEN
         /** Send the command to tell the server we're going to download a file **/
         IF mainframe_connection
         THEN
            n_bytes                    :=
               UTL_TCP.write_line (u_ctrl_con
,                                     v_tsfr_cmd
                                   || ''''
                                   || v_filenamefr
                                   || '''');

--
            IF validate_reply (u_ctrl_con
,                              tsfr_start_code1
,                              tsfr_start_code2
,                              v_reply
                              ) = FALSE
            THEN
               RAISE ctrl_exception;
            END IF;
         ELSE
            n_bytes                    :=
                  UTL_TCP.write_line (u_ctrl_con, v_tsfr_cmd
                                       || v_filenamefr);

--
            IF validate_reply (u_ctrl_con
,                              tsfr_start_code1
,                              tsfr_start_code2
,                              v_reply
                              ) = FALSE
            THEN
               RAISE ctrl_exception;
            END IF;
         END IF;
      ELSIF UPPER (v_tsfr_mode) IN ('LIST','NLST')
         THEN
         /** Send the command to tell the server we're going to list dir contents **/
         IF mainframe_connection
         THEN
            n_bytes                    :=
               UTL_TCP.write_line (u_ctrl_con
,                                     v_tsfr_cmd
                                   || ''''
                                   || '''');

--
            IF validate_reply (u_ctrl_con
,                              tsfr_start_code1
,                              tsfr_start_code2
,                              v_reply
                              ) = FALSE
            THEN
               RAISE ctrl_exception;
            END IF;
         ELSE
            n_bytes                    :=
                  UTL_TCP.write_line (u_ctrl_con,
                                        v_tsfr_cmd
                                       );

--
            IF validate_reply (u_ctrl_con
,                              tsfr_start_code1
,                              tsfr_start_code2
,                              v_reply
                              ) = FALSE
            THEN
               RAISE ctrl_exception;
            END IF;
         END IF;
      ELSE -- Defaults to STOR (PUT) case
         /** Send the command to tell the server we're going to upload a file **/
         IF mainframe_connection
         THEN
            n_bytes                    :=
               UTL_TCP.write_line (u_ctrl_con
,                                     v_tsfr_cmd
                                   || ''''
                                   || v_filenameto
                                   || '''');

--
            IF validate_reply (u_ctrl_con
,                              tsfr_start_code1
,                              tsfr_start_code2
,                              v_reply
                              ) = FALSE
            THEN
               RAISE ctrl_exception;
            END IF;
         ELSE
            n_bytes                    :=
                  UTL_TCP.write_line (u_ctrl_con, v_tsfr_cmd
                                       || v_filenameto);

--
            IF validate_reply (u_ctrl_con
,                              tsfr_start_code1
,                              tsfr_start_code2
,                              v_reply
                              ) = FALSE
            THEN
               RAISE ctrl_exception;
            END IF;
         END IF;
      END IF;

--
      d_trans_start              := SYSDATE;

--
      IF UPPER (v_tsfr_mode) = 'PUT'
      THEN
         IF p_filetype = 'BINARY'
         THEN
            put_remote_binary_data (u_data_con, p_data_blob);
            n_bytes_transmitted        := DBMS_LOB.getlength (p_data_blob);
         ELSE
            LOOP
               BEGIN
                  UTL_FILE.get_line (u_filehandle, v_buffer);
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     EXIT;
               END;

--
--            n_bytes := UTL_TCP.write_line (u_data_con, v_buffer);
/* Trim off Carriage return */
               n_bytes                    :=
                   UTL_TCP.write_line (u_data_con, RTRIM (v_buffer, CHR (13)));
               n_bytes_transmitted        :=   n_bytes_transmitted
                                             + n_bytes;
            END LOOP;
         END IF;
      ELSIF UPPER (v_tsfr_mode) = 'GET'
      THEN
         IF p_filetype = 'BINARY'
         THEN
            p_data_blob                := get_remote_binary_data (u_data_con);
            n_bytes_transmitted        := DBMS_LOB.getlength (p_data_blob);
            put_local_binary_data (p_data                        => p_data_blob
,                                  p_dir                         => v_localpath
,                                  p_file                        => v_filenameto
                                  );
         ELSE
            IF mainframe_connection
            THEN
               LOOP
                  BEGIN
                     v_buffer                   :=
                                          UTL_TCP.get_line (u_data_con, TRUE);

--
               /** Sometimes the TCP/IP buffer sends null data **/
                               /** we only want to receive the actual data **/
                     IF v_buffer IS NOT NULL
                     THEN
                        UTL_FILE.put_line (u_filehandle, v_buffer);
                        n_bytes                    := LENGTH (v_buffer);
                        n_bytes_transmitted        :=
                                                  n_bytes_transmitted
                                                + n_bytes;
                     END IF;
--
                  EXCEPTION
                     WHEN UTL_TCP.end_of_input
                     THEN
              
          EXIT;
                  END;
--
               END LOOP;
            ELSE
               BEGIN
                  LOOP
                     v_buffer                   :=
                                          UTL_TCP.get_line (u_data_con, TRUE);

                     /** Sometimes the TCP/IP buffer sends null data **/
                                     /** we only want to receive the actual data **/
                     IF v_buffer IS NOT NULL
                     THEN
                        UTL_FILE.put_line (u_filehandle, v_buffer);
                        n_bytes                    := LENGTH (v_buffer);
                        n_bytes_transmitted        :=
                                                  n_bytes_transmitted
                                                + n_bytes;
                     END IF;
                  END LOOP;
               EXCEPTION
                  WHEN UTL_TCP.end_of_input
                  THEN
                     NULL;
               END;
            END IF; -- end of IF mainframe connection
            
         END IF; -- end of IF filetype is BINARY
         
      -- ELSIF UPPER (v_tsfr_mode) = 'LIST' OR UPPER (v_tsfr_mode) = 'NLST'
      ELSIF UPPER (v_tsfr_mode) IN ('LIST','NLST')
      THEN
         IF p_filetype = 'BINARY'
         THEN
            p_data_blob                := get_remote_binary_data (u_data_con);
            n_bytes_transmitted        := DBMS_LOB.getlength (p_data_blob);
            put_local_binary_data (p_data                        => p_data_blob
,                                  p_dir                         => v_localpath
,                                  p_file                        => v_filenameto
                                  );
         ELSE
            IF mainframe_connection
            THEN
               LOOP
                  BEGIN
                     v_buffer                   :=
                                          UTL_TCP.get_line (u_data_con, TRUE);

--
               /** Sometimes the TCP/IP buffer sends null data **/
                               /** we only want to receive the actual data **/
                     IF v_buffer IS NOT NULL
                     THEN
                        UTL_FILE.put_line (u_filehandle, v_buffer);
                        n_bytes                    := LENGTH (v_buffer);
                        n_bytes_transmitted        :=
                                                  n_bytes_transmitted
                                                + n_bytes;
                     END IF;
--
                  EXCEPTION
                     WHEN UTL_TCP.end_of_input
                     THEN
                        EXIT;
                  END;
--
               END LOOP;
            ELSE
               BEGIN
                  LOOP
                     v_buffer                   :=
                                          UTL_TCP.get_line (u_data_con, TRUE);

                     /** Sometimes the TCP/IP buffer sends null data **/
                                     /** we only want to receive the actual data **/
                     IF v_buffer IS NOT NULL
                     THEN
                        UTL_FILE.put_line (u_filehandle, v_buffer);
                        n_bytes                    := LENGTH (v_buffer);
                        n_bytes_transmitted        :=
                                                  n_bytes_transmitted
                                                + n_bytes;
                     END IF;
                  END LOOP;
               EXCEPTION
                  WHEN UTL_TCP.end_of_input
                  THEN
                     NULL;
               END;
            END IF; -- end of IF mainframe connection

         END IF; -- end of IF filetype is BINARY
      END IF;

--
      d_trans_end                := SYSDATE;

--
/** Close the file **/
      IF v_mode IN ('r','w','l','n')
      THEN
         UTL_FILE.fclose (u_filehandle);
      END IF;

--
/** Close the Data Connection **/
      UTL_TCP.close_connection (u_data_con);

--
/** Verify the transfer succeeded **/
      IF v_mode IN ('r', 'w', 'l','n')
      THEN
         IF mainframe_connection
         THEN
            IF validate_reply (u_ctrl_connection
,                              tsfr_end_code_mf
,                              v_reply
                              ) = FALSE
            THEN
               RAISE ctrl_exception;
            END IF;
         ELSE
            IF validate_reply (u_ctrl_connection
,                              tsfr_end_code
,                              v_reply
                              ) = FALSE
            THEN
               RAISE ctrl_exception;
            END IF;
         END IF;
      ELSIF v_mode = 'd'
      THEN
         IF validate_reply (u_ctrl_con
,                           delete_code
,                           v_reply
                           ) = FALSE
         THEN
            RAISE ctrl_exception;
         END IF;
      ELSIF v_mode = 'm'
      THEN
         IF validate_reply (u_ctrl_con
,                           rnto_code
,                           v_reply
                           ) = FALSE
         THEN
            RAISE ctrl_exception;
         END IF;
      END IF;
   EXCEPTION
      WHEN ctrl_exception
      THEN
         v_status                   := v_err_status;
         v_error_message            := v_reply;

--
         IF UTL_FILE.is_open (u_filehandle)
         THEN
            UTL_FILE.fclose (u_filehandle);
         END IF;

--
         UTL_TCP.close_connection (u_data_con);
      WHEN UTL_FILE.invalid_path
      THEN
         v_status                   := v_err_status;
         v_error_message            :=
               'Directory '
            || v_localpath
            || ' is not available to UTL_FILE.  Check the init.ora file for valid UTL_FILE directories.';
         UTL_TCP.close_connection (u_data_con);
      WHEN UTL_FILE.invalid_operation
      THEN
         v_status                   := v_err_status;

--
         IF UPPER (v_tsfr_mode) = 'PUT'
         THEN
            v_error_message            :=
                  'The file '
               || v_filenamefr
               || ' in the directory '
               || v_localpath
               || ' could not be opened for reading.';
         ELSIF UPPER (v_tsfr_mode) = 'GET'
         THEN
            v_error_message            :=
                  'The file '
               || v_filenamefr
               || ' in the directory '
               || v_localpath
               || ' could not be opened for writing.';
         ELSIF UPPER (v_tsfr_mode) = 'LIST'
         THEN
            v_error_message            :=
                  'The file '
               || v_filenamefr
               || ' in the directory '
               || v_localpath
               || ' could not be opened for writing, or some other problem occurred with dir cmd.';
         ELSIF UPPER (v_tsfr_mode) = 'DELE'
         THEN
            v_error_message            :=
                  'The file '
               || v_filenamefr
               || ' in the directory '
               || v_localpath
               || ' could not be deleted.';
         ELSIF UPPER (v_tsfr_mode) = 'RNFR'
         THEN
            v_error_message            :=
                  'The file '
               || v_filenamefr
               || ' in the directory '
               || v_localpath
               || ' could not be renamed.';
         END IF;

--
         IF UTL_FILE.is_open (u_filehandle)
         THEN
            UTL_FILE.fclose (u_filehandle);
         END IF;

--
         UTL_TCP.close_connection (u_data_con);
      WHEN UTL_FILE.read_error
      THEN
         v_status                   := v_err_status;
         v_error_message            :=
               'The system encountered an error while trying to read '
            || v_filenamefr
            || ' in the directory '
            || v_localpath;

--
         IF UTL_FILE.is_open (u_filehandle)
         THEN
            UTL_FILE.fclose (u_filehandle);
         END IF;

--
         UTL_TCP.close_connection (u_data_con);
      WHEN UTL_FILE.write_error
      THEN
         v_status                   := v_err_status;
         v_error_message            :=
               'The system encountered an error while trying to write to '
            || v_filenamefr
            || ' in the directory '
            || v_localpath;

--
         IF UTL_FILE.is_open (u_filehandle)
         THEN
            UTL_FILE.fclose (u_filehandle);
         END IF;

--
         UTL_TCP.close_connection (u_data_con);
      WHEN UTL_FILE.internal_error
      THEN
         v_status                   := v_err_status;
         v_error_message            :=
            'The UTL_FILE package encountered an unexpected internal system error.';

--
         IF UTL_FILE.is_open (u_filehandle)
         THEN
            UTL_FILE.fclose (u_filehandle);
         END IF;

--
         UTL_TCP.close_connection (u_data_con);
      WHEN OTHERS
      THEN
         v_status                   := v_err_status;
         v_error_message            := SQLERRM;

--
         IF UTL_FILE.is_open (u_filehandle)
         THEN
            UTL_FILE.fclose (u_filehandle);
         END IF;

--
         UTL_TCP.close_connection (u_data_con);
   END transfer_data;

--

   /*****************************************************************************
   **  Handles connection to host and commands
   *****************************************************************************/
   FUNCTION ftp_files_stage (
      p_error_msg                OUT      VARCHAR2
,     p_files                    IN OUT   t_ftp_rec
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     p_port                     IN       PLS_INTEGER DEFAULT 21
   )
      RETURN BOOLEAN
   IS
      v_username                    VARCHAR2 (30) := p_username;
      v_password                    VARCHAR2 (30) := p_password;
      v_hostname                    VARCHAR2 (30) := p_hostname;
      n_port                        PLS_INTEGER := p_port;
      n_byte_count                  PLS_INTEGER;
      n_first_index                 NUMBER;
      v_msg                         VARCHAR2 (250);
      v_reply                       VARCHAR2 (1000);
      v_pasv_host                   VARCHAR2 (20);
      n_pasv_port                   NUMBER;
      u_ctrl_connection             UTL_TCP.connection;
      invalid_transfer              EXCEPTION;
   BEGIN
      p_error_msg                := 'FTP Successful';
                                   --Assume the overall transfer will succeed
/** Attempt to connect to the host machine **/
      u_ctrl_con                 :=
         login (a_site_in                     => p_hostname
,               a_port_in                     => p_port
,               a_user_name                   => v_username
,               a_user_pass                   => v_password
               );
      u_ctrl_connection          := u_ctrl_con;

      /** We should be logged in, time to transfer all files **/
      FOR i IN p_files.FIRST .. p_files.LAST
      LOOP
         IF p_files.EXISTS (i)
         THEN
            BEGIN
               IF NOT mainframe_connection
               THEN
                  /** Change to the remotepath directory **/
                  n_byte_count               :=
                     UTL_TCP.write_line (u_ctrl_con
,                                           'CWD '
                                         || p_files (i).remotepath);

                  IF validate_reply (u_ctrl_con
,                                    cwd_code
,                                    v_reply
                                    ) = FALSE
                  THEN
--                      print_output (   'user_code= '
--                                    || user_code);
--                      print_output (   'v_reply= '
--                                    || v_reply);
                     RAISE ctrl_exception;
                  END IF;
               END IF;

               /** Switch to IMAGE mode **/
               IF NOT mainframe_connection
               THEN
                  n_byte_count               :=
                                    UTL_TCP.write_line (u_ctrl_con, 'TYPE I');

                  IF validate_reply (u_ctrl_con
,                                    type_code
,                                    v_reply
                                    ) = FALSE
                  THEN
                     RAISE ctrl_exception;
                  END IF;
               ELSE
                  n_byte_count               :=
                                    UTL_TCP.write_line (u_ctrl_con, 'TYPE A');

                  IF validate_reply (u_ctrl_con
,                                    type_code
,                                    v_reply
                                    ) = FALSE
                  THEN
                     RAISE ctrl_exception;
                  END IF;
               END IF;

               /** Get a Passive connection to use for data transfer **/
               n_byte_count               :=
                                       UTL_TCP.write_line (u_ctrl_con, 'PASV');

               IF validate_reply (u_ctrl_con
,                                 pasv_code
,                                 v_reply
                                 ) = FALSE
               THEN
                  RAISE ctrl_exception;
               END IF;

               create_pasv (SUBSTR (v_reply
,                                     INSTR (v_reply
,                                            '('
,                                            1
,                                            1
                                            )
                                    + 1
,                                     INSTR (v_reply
,                                            ')'
,                                            1
,                                            1
                                            )
                                    - INSTR (v_reply
,                                            '('
,                                            1
,                                            1
                                            )
                                    - 1
                                   )
,                           v_pasv_host
,                           n_pasv_port
                           );

               /** Transfer Data **/
               IF UPPER (p_files (i).transfer_mode) = 'PUT'
               THEN
                  transfer_data (u_ctrl_con
,                                p_files (i).localpath
,                                p_files (i).filename
,                                p_files (i).filetype
,                                v_pasv_host
,                                n_pasv_port
,                                p_files (i).transfer_mode
,                                p_files (i).status
,                                p_files (i).error_message
,                                p_files (i).bytes_transmitted
,                                p_files (i).trans_start
,                                p_files (i).trans_end
                                );
               ELSIF UPPER (p_files (i).transfer_mode) = 'GET'
               THEN
                  transfer_data (u_ctrl_con
,                                p_files (i).localpath
,                                p_files (i).filename
,                                p_files (i).filetype
,                                v_pasv_host
,                                n_pasv_port
,                                p_files (i).transfer_mode
,                                p_files (i).status
,                                p_files (i).error_message
,                                p_files (i).bytes_transmitted
,                                p_files (i).trans_start
,                                p_files (i).trans_end
                                );
                  DBMS_OUTPUT.put_line ('TRANSFER_D
ATA COMPLETED');
               ELSIF UPPER (p_files (i).transfer_mode) = 'LIST'
               THEN
                  transfer_data (u_ctrl_con
,                                p_files (i).localpath
,                                p_files (i).filename
,                                p_files (i).filetype
,                                v_pasv_host
,                                n_pasv_port
,                                p_files (i).transfer_mode
,                                p_files (i).status
,                                p_files (i).error_message
,                                p_files (i).bytes_transmitted
,                                p_files (i).trans_start
,                                p_files (i).trans_end
                                );
                  DBMS_OUTPUT.put_line ('LIST_DATA COMPLETED');
               ELSIF UPPER (p_files (i).transfer_mode) = 'NLST'
               THEN
                  transfer_data (u_ctrl_con
,                                p_files (i).localpath
,                                p_files (i).filename
,                                p_files (i).filetype
,                                v_pasv_host
,                                n_pasv_port
,                                p_files (i).transfer_mode
,                                p_files (i).status
,                                p_files (i).error_message
,                                p_files (i).bytes_transmitted
,                                p_files (i).trans_start
,                                p_files (i).trans_end
                                );
                  DBMS_OUTPUT.put_line ('NLST_DATA COMPLETED');
               ELSIF UPPER (p_files (i).transfer_mode) = 'DELE'
               THEN
                  transfer_data (u_ctrl_con
,                                p_files (i).localpath
,                                p_files (i).filename
,                                p_files (i).filetype
,                                v_pasv_host
,                                n_pasv_port
,                                p_files (i).transfer_mode
,                                p_files (i).status
,                                p_files (i).error_message
,                                p_files (i).bytes_transmitted
,                                p_files (i).trans_start
,                                p_files (i).trans_end
                                );
               ELSIF UPPER (p_files (i).transfer_mode) = 'RNFR'
               THEN
                  transfer_data (u_ctrl_con
,                                p_files (i).localpath
,                                p_files (i).filename
,                                p_files (i).filetype
,                                v_pasv_host
,                                n_pasv_port
,                                p_files (i).transfer_mode
,                                p_files (i).status
,                                p_files (i).error_message
,                                p_files (i).bytes_transmitted
,                                p_files (i).trans_start
,                                p_files (i).trans_end
                                );
               ELSE
                  RAISE invalid_transfer;          -- Raise an exception here
               END IF;
            EXCEPTION
               WHEN ctrl_exception
               THEN
                  p_files (i).status         := 'ERROR';
                  p_files (i).error_message  := v_reply;
               WHEN invalid_transfer
               THEN
                  p_files (i).status         := 'ERROR';
                  p_files (i).error_message  :=
                     'Invalid transfer method.  Use PUT or GET (or DELETE / RENAME OPERATION / GET_ATTACHMENT) : ';
            END;
         END IF;
      END LOOP;

/** Send QUIT command **/
      n_byte_count               := UTL_TCP.write_line (u_ctrl_con, 'QUIT');
/** Don't need to VALIDATE QUIT, just close the connection **/
      UTL_TCP.close_connection (u_ctrl_con);
      RETURN TRUE;
   EXCEPTION
      WHEN ctrl_exception
      THEN
         p_error_msg                := v_reply;
         UTL_TCP.close_all_connections;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         p_error_msg                := SQLERRM;
         UTL_TCP.close_all_connections;
         RETURN FALSE;
   END ftp_files_stage;
   
-- --------------------------------------------------------------------------
   FUNCTION get_local_binary_data (
      p_dir                      IN       VARCHAR2
,     p_file                     IN       VARCHAR2
   )
      RETURN BLOB
   IS
-- --------------------------------------------------------------------------
      l_bfile                       BFILE;
      l_data                        BLOB;
      l_dbdir                       VARCHAR2 (100);
   BEGIN
      BEGIN
         SELECT directory_name
           INTO l_dbdir
           FROM all_directories
          WHERE directory_path =    p_dir
                                 || '/';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            print_output (   'Error during GET_LOCAL_BINARY_DATA :: '
                          || SQLCODE
                          || ' - '
                          || SQLERRM);
            RAISE;
      END;

      DBMS_LOB.createtemporary (lob_loc                       => l_data
,                               CACHE                         => TRUE
,                               dur                           => DBMS_LOB.CALL
                               );
      l_bfile                    := BFILENAME (l_dbdir, p_file);
      DBMS_LOB.fileopen (l_bfile, DBMS_LOB.file_readonly);
      DBMS_LOB.loadfromfile (l_data
,                            l_bfile
,                            DBMS_LOB.getlength (l_bfile)
                            );
      DBMS_LOB.fileclose (l_bfile);
      RETURN l_data;
   EXCEPTION
      WHEN OTHERS
      THEN
         print_output (   'Error during GET_LOCAL_BINARY_DATA :: '
                       || SQLCODE
                       || ' - '
                       || SQLERRM);
         DBMS_LOB.fileclose (l_bfile);
         RAISE;
   END get_local_binary_data;

-- --------------------------------------------------------------------------
   FUNCTION get_remote_binary_data (
      u_ctrl_connection          IN OUT   UTL_TCP.connection
   )
      RETURN BLOB
   IS
-- --------------------------------------------------------------------------
      l_amount                      PLS_INTEGER;
      l_buffer                      RAW (32767);
      l_data                        BLOB;
      l_conn                        UTL_TCP.connection := u_ctrl_connection;
   BEGIN
      DBMS_LOB.createtemporary (lob_loc                       => l_data
,                               CACHE                         => TRUE
,                               dur                           => DBMS_LOB.CALL
                               );

      BEGIN
         LOOP
            l_amount                   :=
                                   UTL_TCP.read_raw (l_conn
,                                                    l_buffer
,                                                    32767
                                                    );
            DBMS_LOB.writeappend (l_data
,                                 l_amount
,                                 l_buffer
                                 );
         END LOOP;
      EXCEPTION
         WHEN UTL_TCP.end_of_input
         THEN
            NULL;
         WHEN OTHERS
         THEN
            NULL;
      END;

      RETURN l_data;
   END get_remote_binary_data;

-- --------------------------------------------------------------------------
   PROCEDURE put_local_binary_data (
      p_data                     IN       BLOB
,     p_dir                      IN       VARCHAR2
,     p_file                     IN       VARCHAR2
   )
   IS
-- --------------------------------------------------------------------------
      l_out_file                    UTL_FILE.file_type;
      l_buffer                      RAW (32767);
      l_amount                      BINARY_INTEGER := 32767;
      l_pos                         INTEGER := 1;
      l_blob_len                    INTEGER;
   BEGIN
      l_blob_len                 := DBMS_LOB.getlength (p_data);
      l_out_file                 :=
                                   UTL_FILE.fopen (p_dir
,                                                  p_file
,                                                  'w'
,                                                  32767
                                                  );

      WHILE l_pos < l_blob_len
      LOOP
         DBMS_LOB.READ (p_data
,                       l_amount
,                       l_pos
,                       l_buffer
                       );

         IF l_buffer IS NOT NULL
         THEN
            UTL_FILE.put_raw (l_out_file
,                             l_buffer
,                             TRUE
                             );
         END IF;

         l_pos                      :=   l_pos
                                       + l_amount;
      END LOOP;

      UTL_FILE.fclose (l_out_file);
   EXCEPTION
      WHEN UTL_FILE.invalid_path
      THEN
         print_output
            (   'Error during PUT_LOCAL_BINARY_DATA :: '
             || 'Directory '
             || p_dir
             || ' is not available to UTL_FILE.  Check the init.ora file for valid UTL_FILE directories.');
         RAISE;
      WHEN UTL_FILE.invalid_operation
      THEN
         print_output (   'Error during PUT_LOCAL_BINARY_DATA :: '
                       || 'The file '
                       || p_file
                       || ' in the directory '
                       || p_dir
                       || ' could not be accessed.');

         IF UTL_FILE.is_open (l_out_file)
         THEN
            UTL_FILE.fclose (l_out_file);
         END IF;

         RAISE;
      WHEN UTL_FILE.read_error
      THEN
         print_output
                  (   'Error during PUT_LOCAL_BINARY_DATA :: '
                   || 'The system encountered an error while trying to read '
                   || p_file
                   || ' in the directory '
                   || p_dir);

         IF UTL_FILE.is_open (l_out_file)
         THEN
            UTL_FILE.fclose (l_out_file);
         END IF;

         RAISE;
      WHEN UTL_FILE.write_error
      THEN
         print_output
              (   'Error during PUT_LOCAL_BINARY_DATA :: '
               || 'The system encountered an error while trying to write to '
               || p_file
               || ' in the directory '
               || p_dir);

         IF UTL_FILE.is_open (l_out_file)
         THEN
            UTL_FILE.fclose (l_out_file);
         END IF;

         RAISE;
      WHEN UTL_FILE.internal_error
      THEN
         print_output
            (   'Error during PUT_LOCAL_BINARY_DATA :: '
             || 'The UTL_FILE package encountered an unexpected internal system error.');

         IF UTL_FILE.is_open (l_out_file)
         THEN
            UTL_FILE.fclose (l_out_file);
         END IF;

         RAISE;
      WHEN OTHERS
      THEN
         print_output (   'Error during PUT_LOCAL_BINARY_DATA :: '
                       || SQLCODE
                       || ' - '
                       || SQLERRM);

         IF UTL_FILE.is_open (l_out_file)
         THEN
            UTL_FILE.fclose (l_out_file);
         END IF;

         RAISE;
   END put_local_binary_data;

-- --------------------------------------------------------------------------
   PROCEDURE put_remote_binary_data (
      u_ctrl_connection          IN OUT   UTL_TCP.connection
,     p_data                     IN       BLOB
   )
   IS
-- --------------------------------------------------------------------------
      l_result                      PLS_INTEGER;
      l_buffer                      RAW (32767);
      l_amount                      BINARY_INTEGER := 32767;
      l_pos                         INTEGER := 1;
      l_blob_len                    INTEGER;
      l_conn                        UTL_TCP.connection := u_ctrl_connection;
   BEGIN
      l_blob_len                 := DBMS_LOB.getlength (p_data);

      WHILE l_pos < l_blob_len
      LOOP
         DBMS_LOB.READ (p_data
,                       l_amount
,                       l_pos
,                       l_buffer
                       );
         l_result                   :=
                                UTL_TCP.write_raw (l_conn
,                                                  l_buffer
,                                                  l_amount
                                                  );
         UTL_TCP.FLUSH (l_conn);
         l_pos                      :=   l_pos
                                       + l_amount;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         print_output (   'Error during PUT_REMOTE_BINARY_DATA :: '
                       || SQLCODE
                       || ' - '
                       || SQLERRM);
         RAISE;
   END put_remote_binary_data;

   /*****************************************************************************
   **  Convenience function for single-file PUT
   **  Formats file information for ftp_files_stage function and calls it.
   **
   *****************************************************************************/
   FUNCTION put (
      p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'ASCII'
,     p_mainframe_ftp            IN       BOOLEAN DEFAULT FALSE
,     p_mainframe_cmd            IN       VARCHAR2 DEFAULT NULL
   )
      RETURN BOOLEAN
   IS
      t_files                       t_ftp_rec;
      v_username                    VARCHAR2 (30) := p_username;
      v_password                    VARCHAR2 (50) := p_password;
      v_hostname                    VARCHAR2 (100) := p_hostname;
      n_port                        PLS_INTEGER := p_port;
      v_err_msg                     VARCHAR2 (255);
      b_ftp                         BOOLEAN;
      err_mf_cmd_missing            EXCEPTION;
      err_mf_cmd_mf_ftp_false       EXCEPTION;
   -- MF cmd present but identified as not a MF ftp job
   BEGIN
      IF     p_mainframe_ftp
         AND p_mainframe_cmd IS NULL
      THEN
         RAISE err_mf_cmd_missing;
      ELSIF     p_mainframe_ftp
            AND p_mainframe_cmd IS NOT NULL
      THEN
         mainframe_connection       := TRUE;
         mainframe_cmd              := p_mainframe_cmd;
      ELSIF     NOT p_mainframe_ftp
            AND p_mainframe_cmd IS NOT NULL
      THEN
         RAISE err_mf_cmd_mf_ftp_false;
      ELSIF NOT p_mainframe_ftp
      THEN
         mainframe_connection       := FALSE;
         mainframe_cmd              := NULL;
      END IF;

      t_files (1).localpath      := p_localpath;
      t_files (1).filename       := p_filename;
      t_files (1).remotepath     := p_remotepath;
      t_files (1).filetype       := p_filetype;
      t_files (1).transfer_mode  := 'PUT';
      b_ftp                      :=
         ftp_files_stage (v_err_msg
,                         t_files
,                         v_username
,                         v_password
,                         v_hostname
,                         n_port
                         );

      IF b_ftp = FALSE
      THEN
         v_status                   := 'ERROR';
         v_error_message            := v_err_msg;
         RETURN FALSE;
      ELSIF b_ftp = TRUE
      THEN
         v_status                   := t_files (1).status;
 
        v_error_message            := t_files (1).error_message;
         n_bytes_transmitted        := t_files (1).bytes_transmitted;
         d_trans_start              := t_files (1).trans_start;
         d_trans_end                := t_files (1).trans_end;
         RETURN TRUE;
      END IF;
   EXCEPTION
      WHEN err_mf_cmd_missing
      THEN
         v_status                   := 'ERROR';
         v_error_message            :=
                     'Missing Mainframe Command Parameter. i.e. SITE command';
         RETURN FALSE;
      WHEN err_mf_cmd_mf_ftp_false
      THEN
         v_status                   := 'ERROR';
         v_error_message            :=
              'Mainframe Command Parameter present, but not a Mainframe FTP.';
         RETURN FALSE;
      WHEN OTHERS
      THEN
         v_status                   := 'ERROR';
         v_error_message            := SQLERRM;
         RETURN FALSE;
--print_output(SQLERRM);
   END put;

   /*****************************************************************************
   **  Convenience function for single-file GET
   **  Formats file information for ftp_files_stage function and calls it.
   **
   *****************************************************************************/
   FUNCTION get (
      p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'ASCII'
,     p_mainframe_ftp            IN       BOOLEAN DEFAULT FALSE
,     p_mainframe_cmd            IN       VARCHAR2 DEFAULT NULL
   )
      RETURN BOOLEAN
   IS
      t_files                       t_ftp_rec;
      v_username                    VARCHAR2 (30) := p_username;
      v_password                    VARCHAR2 (50) := p_password;
      v_hostname                    VARCHAR2 (100) := p_hostname;
      n_port                        PLS_INTEGER := p_port;
      v_err_msg                     VARCHAR2 (255);
      b_ftp                         BOOLEAN;
      err_mf_cmd_missing            EXCEPTION;
      err_mf_cmd_mf_ftp_false       EXCEPTION;
   -- MF cmd present but identified as not a MF ftp job
   BEGIN
      IF     p_mainframe_ftp
         AND p_mainframe_cmd IS NULL
      THEN
         RAISE err_mf_cmd_missing;
      ELSIF     p_mainframe_ftp
            AND p_mainframe_cmd IS NOT NULL
      THEN
         mainframe_connection       := TRUE;
         mainframe_cmd              := p_mainframe_cmd;
      ELSIF     NOT p_mainframe_ftp
            AND p_mainframe_cmd IS NOT NULL
      THEN
         RAISE err_mf_cmd_mf_ftp_false;
      ELSIF NOT p_mainframe_ftp
      THEN
         mainframe_connection       := FALSE;
         mainframe_cmd              := NULL;
      END IF;

      t_files (1).localpath      := p_localpath;
      t_files (1).filename       := p_filename;
      t_files (1).remotepath     := p_remotepath;
      t_files (1).filetype       := p_filetype;
      t_files (1).transfer_mode  := 'GET';
      b_ftp                      :=
         ftp_files_stage (v_err_msg
,                         t_files
,                         v_username
,                         v_password
,                         v_hostname
,                         n_port
                         );

      IF b_ftp = FALSE
      THEN
         v_status                   := 'ERROR';
         v_error_message            := v_err_msg;
         RETURN FALSE;
      ELSIF b_ftp = TRUE
      THEN
         v_status                   := t_files (1).status;
         v_error_message            := t_files (1).error_message;
         n_bytes_transmitted        := t_files (1).bytes_transmitted;
         d_trans_start              := t_files (1).trans_start;
         d_trans_end                := t_files (1).trans_end;
         RETURN TRUE;
      END IF;
   EXCEPTION
      WHEN err_mf_cmd_missing
      THEN
         v_status                   := 'ERROR';
         v_error_message            :=
                     'Missing Mainframe Command Parameter. i.e. SITE command';
         RETURN FALSE;
      WHEN err_mf_cmd_mf_ftp_false
      THEN
         v_status                   := 'ERROR';
         v_error_message            :=
              'Mainframe Command Parameter present, but not a Mainframe FTP.';
         RETURN FALSE;
      WHEN OTHERS
      THEN
         v_status                   := 'ERROR';
         v_error_message            := SQLERRM;
         RETURN FALSE;
--print_output(SQLERRM);
   END get;
   
      /*****************************************************************************
   **  Convenience function for dir to local filename
   **  Formats file information for ftp_files_stage function and calls it.
   **
   *****************************************************************************/
   FUNCTION dir (
      p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'ASCII'
,     p_mainframe_ftp            IN       BOOLEAN DEFAULT FALSE
,     p_mainframe_cmd            IN       VARCHAR2 DEFAULT NULL
   )
      RETURN BOOLEAN
   IS
      t_files                       t_ftp_rec;
      v_username                    VARCHAR2 (30) := p_username;
      v_password                    VARCHAR2 (50) := p_password;
      v_hostname                    VARCHAR2 (100) := p_hostname;
      n_port                        PLS_INTEGER := p_port;
      v_err_msg                     VARCHAR2 (255);
      b_ftp                         BOOLEAN;
      err_mf_cmd_missing            EXCEPTION;
      err_mf_cmd_mf_ftp_false       EXCEPTION;
   -- MF cmd present but identified as not a MF ftp job
   BEGIN
      IF     p_mainframe_ftp
         AND p_mainframe_cmd IS NULL
      THEN
         RAISE err_mf_cmd_missing;
      ELSIF     p_mainframe_ftp
            AND p_mainframe_cmd IS NOT NULL
      THEN
         mainframe_connection       := TRUE;
         mainframe_cmd              := p_mainframe_cmd;
      ELSIF     NOT p_mainframe_ftp
            AND p_mainframe_cmd IS NOT NULL
      THEN
         RAISE err_mf_cmd_mf_ftp_false;
      ELSIF NOT p_mainframe_ftp
      THEN
         mainframe_connection       := FALSE;
         mainframe_cmd              := NULL;
      END IF;

      t_files (1).localpath      := p_localpath;
      t_files (1).filename       := p_filename;
      t_files (1).remotepath     := p_remotepath;
      t_files (1).filetype       := p_filetype;
      t_files (1).transfer_mode  := 'LIST';
      b_ftp                      :=
         ftp_files_stage (v_err_msg
,                         t_files
,                         v_username
,                         v_password
,                         v_hostname
,                         n_port
                         );

      IF b_ftp = FALSE
      THEN
         v_status                   := 'ERROR';
         v_error_message            := v_err_msg;
         RETURN FALSE;
      ELSIF b_ftp = TRUE
      THEN
         v_status                   := t_files (1).status;
         v_error_message            := t_files (1).error_message;
         n_bytes_transmitted        := t_files (1).bytes_transmitted;
         d_trans_start              := t_files (1).trans_start;
         d_trans_end                := t_files (1).trans_end;
         RETURN TRUE;
      END IF;
   EXCEPTION
      WHEN err_mf_cmd_missing
      THEN
         v_status                   := 'ERROR';
         v_error_message            :=
                     'Missing Mainframe Command Parameter. i.e. SITE command';
         RETURN FALSE;
      WHEN err_mf_cmd_mf_ftp_false
      THEN
         v_status                   := 'ERROR';
         v_error_message            :=
              'Mainframe Command Parameter present, but not a Mainframe FTP.';
         RETURN FALSE;
      WHEN OTHERS
      THEN
         v_status                   := 'ERROR';
         v_error_message            := SQLERRM;
         RETURN FALSE;
--print_output(SQLERRM);
   END dir;

      /*****************************************************************************
   **  Convenience function for dir to local filename
   **  Formats file information for ftp_files_stage function and calls it.
   **
   *****************************************************************************/
   FUNCTION ls (
      p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'ASCII'
,     p_mainframe_ftp            IN       BOOLEAN DEFAULT FALSE
,     p_mainframe_cmd            IN       VARCHAR2 DEFAULT NULL
   )
      RETURN BOOLEAN
   IS
      t_files                       t_ftp_rec;
      v_username                    VARCHAR2 (30) := p_username;
      v_password                    VARCHAR2 (50) := p_password;
      v_hostname                    VARCHAR2 (100) := p_hostname;
      n_port                        PLS_INTEGER := p_port;
      v_err_msg                     VARCHAR2 (255);
      b_ftp                         BOOLEAN;
      err_mf_cmd_missing            EXCEPTION;
      err_mf_cmd_mf_ftp_false       EXCEPTION;
   -- MF cmd present but identified as not a MF ftp job
   BEGIN
      IF     p_mainframe_ftp
         AND p_mainframe_cmd IS NULL
      THEN
         RAISE err_mf_cmd_missing;
      ELSIF     p_mainframe_ftp
            AND p_mainframe_cmd IS NOT NULL
      THEN
         mainframe_connection       := TRUE;
         mainframe_cmd              := p_mainframe_cmd;
      ELSIF     NOT p_mainframe_ftp
            AND p_mainframe_cmd IS NOT NULL
      THEN
         RAISE err_mf_cmd_mf_ftp_false;
      ELSIF NOT p_mainframe_ftp
      THEN
         mainframe_connection       := FALSE;
         mainframe_cmd              := NULL;
      END IF;

      t_files (1).localpath      := p_localpath;
      t_files (1).filename       := p_filename;
      t_files (1).remotepath     := p_remotepath;
      t_files (1).filetype       := p_filetype;
      t_files (1).transfer_mode  := 'NLST';
      b_ftp                      :=
         ftp_files_stage (v_err_msg
,                         t_files
,                         v_username
,                         v_password
,                         v_hostname
,                         n_port
                         );

      IF b_ftp = FALSE
      THEN
         v_status                   := 'ERROR';
         v_error_message            := v_err_msg;
         RETURN FALSE;
      ELSIF b_ftp = TRUE
      THEN
         v_status                   := t_files (1).status;
         v_error_message            := t_files (1).error_message;
         n_bytes_transmitted        := t_files (1).bytes_transmitted;
         d_trans_start              := t_files (1).trans_start;
         d_trans_end                := t_files (1).trans_end;
         RETURN TRUE;
      END IF;
   EXCEPTION
      WHEN err_mf_cmd_missing
      THEN
         v_status                   := 'ERROR';
         v_error_message            :=
                     'Missing Mainframe Command Parameter. i.e. SITE command';
         RETURN FALSE;
      WHEN err_mf_cmd_mf_ftp_false
      THEN
         v_status                   := 'ERROR';
         v_error_message            :=
              'Mainframe Command Parameter present, but not a Mainframe FTP.';
         RETURN FALSE;
      WHEN OTHERS
      THEN
         v_status                   := 'ERROR';
         v_error_message            := SQLERRM;
         RETURN FALSE;
--print_output(SQLERRM);
   END ls;

   /*****************************************************************************
   **  Convenience function for single-file DELETE
   **  Formats file information for ftp_files_stage function and calls it.
   **
   *****************************************************************************/
   FUNCTION remove (
      p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'BINARY'
,     p_mainframe_connection     IN       BOOLEAN DEFAULT FALSE
   )
      RETURN BOOLEAN
   IS
      t_files                       t_ftp_rec;
      v_username                    VARCHAR2 (30) := p_username;
      v_password                    VARCHAR2 (50) := p_password;
      v_hostname                    VARCHAR2 (100) := p_hostname;
      n_port                        PLS_INTEGER := p_port;
      v_err_msg                     VARCHAR2 (255);
      b_ftp                         BOOLEAN;
   BEGIN
      IF p_mainframe_connection
      THEN
         mainframe_connection       := TRUE;
      END IF;

      t_files (1).localpath      := p_localpath;
      t_files (1).filename       := p_filename;
      t_files (1).remotepath     := p_remotepath;
      t_files (1).filetype       := p_filetype;
      t_files (1).transfer_mode  := 'DELE';
      b_ftp                      :=
         ftp_files_stage (v_err_msg
,                         t_files
,                         v_username
,                         v_password
,                         v_hostname
,                         n_port
                         );

      IF b_ftp = FALSE
      THEN
         v_status                   := 'ERROR';
         v_error_message            := v_err_msg;
         RETURN FALSE;
      ELSIF b_ftp = TRUE
      THEN
         v_status                   := t_files (1).status;
         v_error_message            := t_files (1).error_message;
         n_bytes_transmitted        := t_files (1).bytes_transmitted;
         d_trans_start              := t_files (1).trans_start;
         d_trans_end                := t_files (1).trans_end;
         RETURN TRUE;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_status                   := 'ERROR';
         v_error_message            := SQLERRM;
         RETURN FALSE;
--print_output(SQLERRM);
   END remove;

   /*****************************************************************************
   **  Convenience function for single-file RENAME
   **  Formats file information for ftp_fi
les_stage function and calls it.
   **
   *****************************************************************************/
   FUNCTION ren (
      p_localpath                IN       VARCHAR2
,     p_filename                 IN       VARCHAR2
,     p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     n_bytes_transmitted        OUT      NUMBER
,     d_trans_start              OUT      DATE
,     d_trans_end                OUT      DATE
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'BINARY'
,     p_mainframe_connection     IN       BOOLEAN DEFAULT FALSE
   )
      RETURN BOOLEAN
   IS
      t_files                       t_ftp_rec;
      v_username                    VARCHAR2 (30) := p_username;
      v_password                    VARCHAR2 (50) := p_password;
      v_hostname                    VARCHAR2 (100) := p_hostname;
      n_port                        PLS_INTEGER := p_port;
      v_err_msg                     VARCHAR2 (255);
      b_ftp                         BOOLEAN;
   BEGIN
      IF p_mainframe_connection
      THEN
         mainframe_connection       := TRUE;
      END IF;

      t_files (1).localpath      := p_localpath;
      t_files (1).filename       := p_filename;
      t_files (1).remotepath     := p_remotepath;
      t_files (1).filetype       := p_filetype;
      t_files (1).transfer_mode  := 'RNFR';
      b_ftp                      :=
         ftp_files_stage (v_err_msg
,                         t_files
,                         v_username
,                         v_password
,                         v_hostname
,                         n_port
                         );

      IF b_ftp = FALSE
      THEN
         v_status                   := 'ERROR';
         v_error_message            := v_err_msg;
         RETURN FALSE;
      ELSIF b_ftp = TRUE
      THEN
         v_status                   := t_files (1).status;
         v_error_message            := t_files (1).error_message;
         n_bytes_transmitted        := t_files (1).bytes_transmitted;
         d_trans_start              := t_files (1).trans_start;
         d_trans_end                := t_files (1).trans_end;
         RETURN TRUE;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_status                   := 'ERROR';
         v_error_message            := SQLERRM;
         RETURN FALSE;
--print_output(SQLERRM);
   END REN;

--
   FUNCTION verify_server (
      p_remotepath               IN       VARCHAR2
,     p_username                 IN       VARCHAR2
,     p_password                 IN       VARCHAR2
,     p_hostname                 IN       VARCHAR2
,     v_status                   OUT      VARCHAR2
,     v_error_message            OUT      VARCHAR2
,     p_port                     IN       PLS_INTEGER DEFAULT 21
,     p_filetype                 IN       VARCHAR2 := 'BINARY'
,     p_mainframe_connection     IN       BOOLEAN DEFAULT FALSE
   )
      RETURN BOOLEAN
   IS
      v_username                    VARCHAR2 (30) := p_username;
      v_password                    VARCHAR2 (30) := p_password;
      v_hostname                    VARCHAR2 (30) := p_hostname;
      v_remotepath                  VARCHAR2 (255) := p_remotepath;
      n_port                        PLS_INTEGER := p_port;
      u_ctrl_connection             UTL_TCP.connection;
      n_byte_count                  PLS_INTEGER;
      n_first_index                 NUMBER;
      v_msg                         VARCHAR2 (250);
      v_reply                       VARCHAR2 (1000);
      v_pasv_host                   VARCHAR2 (20);
      n_pasv_port                   NUMBER;
   BEGIN
      IF p_mainframe_connection
      THEN
         mainframe_connection       := TRUE;
      END IF;

      v_error_message            := 'Server connection is valid.';
                                   --Assume the overall transfer will succeed
/** Attempt to connect to the host machine **/
      u_ctrl_con                 :=
         login (a_site_in                     => p_hostname
,               a_port_in                     => p_port
,               a_user_name                   => v_username
,               a_user_pass                   => v_password
               );
      u_ctrl_connection          := u_ctrl_con;

      /** We should be logged in, time to verify remote path **/
      BEGIN
         IF NOT mainframe_connection
         THEN
            /** Change to the remotepath directory **/
            n_byte_count               :=
               UTL_TCP.write_line (u_ctrl_connection, 'CWD '
                                    || v_remotepath);

            IF validate_reply (u_ctrl_connection
,                              cwd_code
,                              v_reply
                              ) = FALSE
            THEN
               print_output (   'user_code= '
                             || user_code);
               print_output (   'v_reply= '
                             || v_reply);
               RAISE ctrl_exception;
            END IF;
         END IF;

         /** Switch to IMAGE mode **/
         n_byte_count               :=
                              UTL_TCP.write_line (u_ctrl_connection, 'TYPE I');

         IF validate_reply (u_ctrl_connection
,                           type_code
,                           v_reply
                           ) = FALSE
         THEN
            RAISE ctrl_exception;
         END IF;

         /** Get a Passive connection to use for data transfer **/
         n_byte_count               :=
                                UTL_TCP.write_line (u_ctrl_connection, 'PASV');

         IF validate_reply (u_ctrl_connection
,                           pasv_code
,                           v_reply
                           ) = FALSE
         THEN
            RAISE ctrl_exception;
         END IF;

         create_pasv (SUBSTR (v_reply
,                               INSTR (v_reply
,                                      '('
,                                      1
,                                      1
                                      )
                              + 1
,                               INSTR (v_reply
,                                      ')'
,                                      1
,                                      1
                                      )
                              - INSTR (v_reply
,                                      '('
,                                      1
,                                      1
                                      )
                              - 1
                             )
,                     v_pasv_host
,                     n_pasv_port
                     );
      EXCEPTION
         WHEN ctrl_exception
         THEN
            v_status                   := 'ERROR';
            v_error_message            := v_reply;
      END;

/** Send QUIT command **/
      n_byte_count               :=
                                UTL_TCP.write_line (u_ctrl_connection, 'QUIT');
/** Don't need to VALIDATE QUIT, just close the connection **/
      UTL_TCP.close_connection (u_ctrl_connection);
      RETURN TRUE;
   EXCEPTION
      WHEN ctrl_exception
      THEN
         v_error_message            := v_reply;
         UTL_TCP.close_all_connections;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         v_error_message            := SQLERRM;
         UTL_TCP.close_all_connections;
         RETURN FALSE;
   END verify_server;
END;
/



