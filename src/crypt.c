/*
 * Encryption utilites
 * Bradley Williams
 * {allegra,ihnp4,uiucdcs,ctvax}!convex!williams
 * $Revision: 7.16 $
 * Modified for sc-im by DHMike57
 */
#ifdef CRYPT_PATH

#include <sys/types.h>
#include <sys/file.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <ncurses.h>
#include "sc.h"
#include "macros.h"
#include "y.tab.h"
#include "tui.h"
#include "file.h"
#include "conf.h"
#include "crypt.h"

#define MAXKEYWORDSIZE 30
char	    KeyWord[MAXKEYWORDSIZE] = {""};
char	    KeyWordConfirm[MAXKEYWORDSIZE] = {""};

extern struct session * session;
int Crypt=0;

/**
 * \brief Try to open a ccrypt encrypted spreadsheet file.
 *
 * \param[in] fname file name
 *
 * \return 0 on success; -1 on error
 */
int creadfile(char *save )
{
    register FILE *f;
    int pipefd[2];
    int fildes;
    int pid;
    char pwfilename[64] = "/tmp/sc_ccrypt-XXXXXX";

    int fd;

    if ((fildes = open(findhome(save), O_RDONLY, 0)) < 0) {
        sc_error ("Can't read file \"%s\"", save);
        return -1;
    }

    if (pipe(pipefd) < 0) {
        sc_error("Can't make pipe to child");
        return -1;
    }

    strlcpy(KeyWord,ui_query("Enter key:"),sizeof KeyWord);

    if ((fd = mkstemp (pwfilename)) == -1){
        sc_error ("mkstemp KeyWord file failed");
        unlink (pwfilename);
        return -1;
    }
    if(write(fd,KeyWord,strlen(KeyWord)) == -1){
        sc_error("error writing KeyWord file");
        unlink (pwfilename);
        return -1;
    }
    if ((pid=fork()) == 0) {		/* if child		 */
        (void) close(0);		/* close stdin		 */
        (void) close(1);		/* close stdout		 */
        (void) close(2);		/* close stderr		 */
        (void) close(pipefd[0]);	/* close pipe input	 */
        (void) dup(fildes);		/* standard in from file */
        (void) dup(pipefd[1]);		/* connect to pipe	 */
        (void) fprintf(stderr, " ");
        (void) execl(CRYPT_PATH, "ccrypt","-q","-c", "-k", pwfilename, (char *) NULL);
        exit(-127);
    } else {				/* else parent */
        (void) close(fildes);
        (void) close(pipefd[1]);	/* close pipe output */
        if ((f = fdopen(pipefd[0], "r")) == (FILE *)0) {
            (void) kill(pid, 9);
            sc_error("Can't fdopen file \"%s\"", save);
            (void)close(pipefd[0]);
            return -1;
        }
    }

    while (fgets(line, sizeof(line), f)) {
        linelim = 0;
        if (line[0] != '#') (void) yyparse();
    }
	if (fclose(f) == EOF) {
		sc_error("fclose(pipefd): %s", strerror(errno));
	}
    (void) close(pipefd[0]);

    int status;
    int return_status=-1 ;
    waitpid(pid,&status,0);
    if (WIFEXITED(status) ) {
        int exit_status = WEXITSTATUS(status);
        switch(exit_status){
            case 0:
                return_status=0;
                break;
            case 129:
                sc_error("execl(%s, \"ccrypt\", %s, 0) in creadfile() failed",CRYPT_PATH,KeyWord);
                break;
            case 4:
                sc_error("ccrypt wrong password");
                break;
            case 3:
                sc_error("ccrypt fatal io");
                break;
            case 2:
                sc_error("ccrypt out of memory");
                break;
            case 1:
                sc_error("ccrypt illegal command line");
                break;
            default:
                sc_error("ccrypt error exit status %d",exit_status);
            }
        }
    linelim = -1;

    // Zero out the password file before deleting it
    lseek(fd,0,SEEK_SET);
    memset(KeyWord, '\0', sizeof(KeyWord));
    if(write(fd,KeyWord,sizeof KeyWord) == -1)
        sc_error("error zeroing KeyWord file");

    close(fd);
    unlink (pwfilename);

    return return_status;
}

/*
 * \brief Write current Doc(roman) to file in encrypted (.sc,cpt) sc-im format
 * \details Write a file encrypted with ccryot. Receives file name.
 * \param[in] fname file name
 * \param[in] verbose
 *
 * \return 0 on success; -1 on error
 */
  int cwritefile(char *fname, int verbose)
  {
      register FILE *f;
      int pipefd[2];
      int fildes;
      int pid;
      char save[PATHLEN];
      char *fn;
      int fd;
      struct roman * doc = session->cur_doc;
      char * curfile = doc->name;
      char pwfilename[64] = "/tmp/sc_ccrypt-XXXXXX";

      fn = fname;
      while (*fn && (*fn == ' '))	/* Skip leading blanks */
        fn++;

      strlcpy(save, fname, sizeof save);

      if (pipe(pipefd) < 0) {
          sc_error("Can't make pipe to child\n");
          return (-1);
      }

      if (KeyWord[0] == '\0') {
          strlcpy(KeyWord, ui_query("Enter key:"), sizeof KeyWord);
          strlcpy(KeyWordConfirm, ui_query("Confirm key:"), sizeof KeyWord);
          if(strcmp(KeyWord,KeyWordConfirm) != 0){
              KeyWord[0]='\0';
              sc_error("Keys do not match");
              return -1;
          }
      }
      if ((fd = mkstemp (pwfilename)) == -1){
          sc_error ("mkstemp KeyWord file failed");
          unlink (pwfilename);
          return -1;
      }
      if(write(fd,KeyWord,strlen(KeyWord)) == -1){
          sc_error("error writing KeyWord file");
          unlink (pwfilename);
          return -1;
      }
    if ((fildes = open (save, O_TRUNC|O_WRONLY|O_CREAT, 0600)) < 0) {
        sc_error("Can't create file \"%s\"", save);
        return (-1);
    }

      if ((pid=fork()) == 0) {			/* if child		 */
          (void) close(0);			/* close stdin		 */
          (void) close(1);			/* close stdout		 */
          (void) close(2);			/* close stderr		 */
          (void) close(pipefd[1]);		/* close pipe output	 */
          (void) dup(pipefd[0]);			/* connect to pipe input */
          (void) dup(fildes);			/* standard out to file  */
          (void) fprintf(stderr, " ");
          (void) execl(CRYPT_PATH, "ccrypt", "-k", pwfilename, (char *) NULL);
          exit (-127);
      }
      else {				  /* else parent */
          (void) close(fildes);
          (void) close(pipefd[0]);		  /* close pipe input */
          f = fdopen(pipefd[1], "w");
          if (f == 0) {
              (void) kill(pid, -9);
              sc_error("Can't fdopen file \"%s\"", save);
              (void) close(pipefd[1]);
              return (-1);
          }
      }

      write_fd(f, session->cur_doc);

  	if (fclose(f) == EOF) {
  		sc_error("fclose(pipefd): %s", strerror(errno));
  	}
      (void) close(pipefd[1]);
//      while (pid != wait(&fildes)) /**/;
    int status;
    int return_status=-1 ;
    waitpid(pid,&status,0);
    if (WIFEXITED(status) ) {
        int exit_status = WEXITSTATUS(status);
        switch(exit_status){
            case 0:
                return_status=0;
                break;
            case 129:
                sc_error("execl(%s, \"ccrypt\", %s, 0) in creadfile() failed",CRYPT_PATH,KeyWord);
                break;
            case 4:
                sc_error("ccrypt wrong password");
                break;
            case 3:
                sc_error("ccrypt fatal io");
                break;
            case 2:
                sc_error("ccrypt out of memory");
                break;
            case 1:
                sc_error("ccrypt illegal command line");
                break;
            default:
                sc_error("ccrypt error exit status %d",exit_status);
            }
        }

//      strlcpy(curfile, save, sizeof curfile);

      sc_info("File \"%s\" written (encrypted).", curfile);

      // Zero out the password file before deleting it
      lseek(fd,0,SEEK_SET);
      memset(KeyWord, '\0', sizeof(KeyWord));
      if(write(fd,KeyWord,sizeof KeyWord) == -1)
          sc_error("error zeroing KeyWord file");

      (void) close(fd);
      unlink (pwfilename);

      if (get_conf_int("pwd_keep")==1)
         strlcpy(KeyWord,KeyWordConfirm,sizeof KeyWord);
      else
          memset(KeyWordConfirm, '\0', sizeof(KeyWordConfirm));

      session->cur_doc->modflg = 0;
      return return_status;
  }


void clear_keyword(){
      memset(KeyWord, '\0', sizeof(KeyWord));
      memset(KeyWordConfirm, '\0', sizeof(KeyWordConfirm));
}



#endif /* CRYPT_PATH */
