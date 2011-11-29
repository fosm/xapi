#include <stdio.h>
#include "gtmxc_types.h"
#define BUF_LEN 1024
int main()
{
 	gtm_char_t	port[] = "6520";
	gtm_char_t	logLevel[] = "0";
	gtm_char_t	msgbuf[BUF_LEN];
        gtm_status_t    status;
        status = gtm_init();
        if (status != 0)
        {
            gtm_zstatus(msgbuf, BUF_LEN);
            return status;
        }
        status = gtm_ci("zappyd", port, logLevel);
        if (status != 0)
        {
            gtm_zstatus(msgbuf, BUF_LEN);
            fprintf(stderr, "%s\n", msgbuf);
            return status;
        }
        return 0;
}
