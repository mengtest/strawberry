#pragma once
#ifndef SSOCK_H
#define SSOCK_H

#include "sssl.h"

#define SSOCK_CONNECT    1
#define SSOCK_CONNECTING 2
#define SSOCK_CONNECTED  3
#define SSOCK_CLOSE      4
#define SSOCK_ERROR      5

typedef int (*ssock_cb)(struct http_response* resp, void *ud);

struct ssock {
	struct sssl_ctx *sssl;
	int fds[1];
	int state[1];
	int ssslidx[1];
	int idx;
};

/*
	Represents an HTTP html response
*/
struct http_response {
	struct parsed_url *request_uri;
	char *body;
	char *status_code;
	int status_code_int;
	char *status_text;
	char *request_headers;
	char *response_headers;
};

struct ssock * ssock_alloc();
void           ssock_free(struct ssock *self);


int            ssock_connect(struct ssock *self, const char *addr, int port);

int            ssock_update(struct ssock *self);
int            ssock_send(struct ssock *self, const char *buf, int size);


struct http_response*
ssock_req(struct ssock *self, char *http_headers, struct parsed_url *purl);

struct http_response*
ssock_get(struct ssock *self, char *url, char *custom_headers);

struct http_response*
ssock_head(struct ssock *self, char *url, char *custom_headers);

struct http_response*
ssock_post(struct ssock *self, char *url, char *custom_headers, char *post_data);

int            ssock_shutdown(struct ssock *self, int how);
int            ssock_close(struct ssock *self);
int            ssock_clear(struct ssock *self);

#endif // !SSOCK_H

