#include <stdio.h>
#include "gtmxc_types.h"
#define BUF_LEN 1024
int main(int argc, char *argv[])
{
        gtm_char_t      port[] = "6520";
        gtm_char_t      logLevel[] = "0";
        gtm_char_t      process[100];
        gtm_char_t      msgbuf[BUF_LEN];
        gtm_status_t    status;
        status = gtm_init();
        if (status != 0)
        {
            gtm_zstatus(msgbuf, BUF_LEN);
            return status;
        }
        status = gtm_ci("zappy", argv[1], argv[2], argv[3]);
        if (status != 0)
        {
            gtm_zstatus(msgbuf, BUF_LEN);
            fprintf(stderr, "%s\n", msgbuf);
            return status;
        }
        return 0;
}
