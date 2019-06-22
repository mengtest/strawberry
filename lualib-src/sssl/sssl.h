#pragma once
#ifndef SSSL_H
#define SSSL_H

#include "write_buffer.h"

// #define SSSL_NORMAL     0
#define SSSL_CONNECT    1
#define SSSL_CONNECTING 2
#define SSSL_CONNECTED  3
#define SSSL_CLOSE      4
#define SSSL_ERROR      5

typedef int (*sssl_cb)(void *ud, const char * cmd, int how);

struct sssl_ctx;
struct sssl_ctx *
sssl_alloc(void *ud, sssl_cb cb);

void         
sssl_free(struct sssl_ctx *self);

int          
sssl_connect(struct sssl_ctx *self, const char *host, int port);

struct write_buffer *
sssl_poll(struct sssl_ctx *self, int idx, const char *buf, int sz);

int          
sssl_send(struct sssl_ctx *self, int idx, const char *buf, int sz);

int          
sssl_recv(struct sssl_ctx *self, int idx, const char *buf, int sz);

int          sssl_get_state(struct sssl_ctx *self, int idx);
int          sssl_shutdown(struct sssl_ctx *self, int idx, int how);
int          sssl_close(struct sssl_ctx *self, int idx);



#endif // !SSSL_H
