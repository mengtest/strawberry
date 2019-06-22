#include "sssl.h"

#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <assert.h>
#include <string.h>

#define MAX_SSL_NUM (1)
#define BUFFER_SIZE (2048)
#define CMD_CONNECT    'C'
#define CMD_CONNECTED  'D'
#define CMD_SENT_SHUTDOWNED   'S'
#define CMD_RECEIVED_SHUTDOWNED 'X'

struct sssl {
	SSL       *ssl;
	BIO       *send_bio;
	BIO       *recv_bio;
	struct wb_list *l;
	int        state;
	int        xsend;   // shutdown send
	int        xrecv;   // shutdown recv
};

struct sssl_ctx {
	SSL_CTX    *ssl_ctx;
	void       *ud;
	sssl_cb     callback;
	struct sssl e[1];
};

static int
sssl_handle_err(struct sssl *self, int code, const char *tips);

/*
** @breif 只管把所有数据都推向出去
** @return 获取的数据的size
*/
static int
sssl_write_to_so(struct sssl *self) {
	int offset = 0;
	char BUF[BUFFER_SIZE] = { 0 };
	for (; ; ) {
		int nread = BIO_read(self->send_bio, BUF + offset, BUFFER_SIZE - offset);
		if (nread <= 0) {
			sssl_handle_err(self, nread, "sssl write ssock, BIO_read error.");
			break;
		}
		offset += nread;
	}
	if (offset > 0) {
		struct write_buffer * wb = wb_list_alloc_wb(self->l, offset);
		memcpy(wb->buffer, BUF, offset);
		wb->len = offset;
		wb_list_push_wb(self->l, wb);
	}
	return 0;
}

/*
** @breif 只管处理错误
*/
static int
sssl_handle_err(struct sssl *self, int code, const char *tips) {
	assert(self != NULL && tips != NULL);
	int err = SSL_get_error(self->ssl, code);
	if (err == SSL_ERROR_SSL) {
		printf("SSL_ERROR_SSL : %s\r\n", tips);
	} else if (err == SSL_ERROR_WANT_READ) {
		// waitting for poll buf.
		printf("SSL_ERROR_WANT_READ : %s\r\n", tips);
	} else if (err == SSL_ERROR_WANT_WRITE) {
		printf("SSL_ERROR_WANT_WRITE : %s\r\n", tips);
		sssl_write_to_so(self);
	} else if (err == SSL_ERROR_WANT_CONNECT) {
		printf("SSL_ERROR_WANT_WRITE : %s\r\n", tips);
	} else if (err == SSL_ERROR_SYSCALL) {
		printf("SSL_ERROR_SYSCALL : %s\r\n", tips);
	} else {
		printf("DEFAULT ERROR : %d\r\n", err);
	}
	return err;
}

struct sssl_ctx *
	sssl_alloc(void *ud, sssl_cb cb) {
	SSL_library_init();
	OpenSSL_add_all_algorithms();
	SSL_load_error_strings();
	ERR_load_BIO_strings();

	// ssl ctx
	struct sssl_ctx *inst = (struct sssl_ctx *)malloc(sizeof(*inst));
	memset(inst, 0, sizeof(*inst));
	inst->ssl_ctx = SSL_CTX_new(SSLv23_client_method());

	inst->ud = ud;
	inst->callback = cb;

	return inst;
}

void
sssl_free(struct sssl_ctx *self) {
	for (size_t i = 0; i < MAX_SSL_NUM; i++) {
		struct sssl *ssl = &self->e[i];
		assert(ssl->state == SSSL_CLOSE);
		wb_list_free(ssl->l);

		BIO_free(ssl->send_bio);
		BIO_free(ssl->recv_bio);

		SSL_free(ssl->ssl);
	}

	SSL_CTX_free(self->ssl_ctx);
	ERR_free_strings();

	free(self);
}

int
sssl_connect(struct sssl_ctx *self, const char *host, int port) {
	// ssl
	self->e[0].ssl = SSL_new(self->ssl_ctx);

	// bio
	self->e[0].send_bio = BIO_new(BIO_s_mem());
	self->e[0].recv_bio = BIO_new(BIO_s_mem());

	SSL_set_bio(self->e[0].ssl, self->e[0].recv_bio, self->e[0].send_bio);
	self->e[0].l = wb_list_new();
	self->e[0].state = SSSL_CONNECT;

	// callback socket connect
	self->callback(self->ud, 'C', 0);
	// ssl connect
	self->e[0].state = SSSL_CONNECTING;

	SSL_set_connect_state(self->e[0].ssl);
	int ret = SSL_connect(self->e[0].ssl);
	if (ret == 1) {
		printf("SSL_connect successfully.");
	} else {
		sssl_handle_err(&self->e[0], ret, "SSL_connect.");
	}
	sssl_write_to_so(&self->e[0]);
	return 0;
}

/*
** @breif 此函数接受socket数据，并传送数据到ssl，无论怎样
** @return 返回数据传送是否正确就行
**         正确，返回发送的数据，错误返回0
*/

struct write_buffer *
	sssl_poll(struct sssl_ctx *self, int idx, const char *buf, int sz) {
	assert(idx >= 0 && idx < MAX_SSL_NUM);
	struct sssl *ssl = &self->e[idx];

	// write raw data
	if (buf != NULL && sz > 0) {
		int nw = 0;
		while (nw < sz) {
			int w = BIO_write(ssl->recv_bio, buf + nw, sz - nw);
			nw += w;
		}
		assert(nw == sz);
	}

	// handshake 
	if (SSSL_CONNECT <= ssl->state && ssl->state <= SSSL_CONNECTED) {
		// 判断hanshake是否完成
		if (!SSL_is_init_finished(ssl)) {
			int ret = SSL_do_handshake(ssl);
			sssl_write_to_so(ssl);
			if (ret == 1) {
				printf("openssl handshake success.\r\n");
				ssl->state = SSSL_CONNECTED;
				self->callback(self->ud, 'D', 0);
			} else {
				sssl_handle_err(self, ret, "SSL_do_hanshake.");
			}
			return ret;
		} else {
			if (ssl->state != SSSL_CONNECTED) {
				ssl->state = SSSL_CONNECTED;
				self->callback(self->ud, 'D', 0);
			}
			if (ssl->xsend == 1) {
				int ret = SSL_shutdown(ssl);
				if (ret == 1) {
					ssl->xsend = 2;
					self->callback(self->ud, CMD_SENT_SHUTDOWNED, 0);
					printf("SSL_shutdown successfully.");
				} else if (ret == 0) {
					sssl_handle_err(self, ret, "shutdown is not yet finished.");
				} else {
					sssl_handle_err(self, ret, "shutdown is not successful.");
				}
			}
			if (ssl->xrecv == 1) {
				int ret = SSL_shutdown(ssl);
				if (ret == 1) {
					ssl->xrecv = 2;
					self->callback(self->ud, CMD_RECEIVED_SHUTDOWNED, 0);
					printf("SSL_shutdown successfully.");
				} else if (ret == 0) {
					sssl_handle_err(self, ret, "shutdown is not yet finished.");
				} else {
					sssl_handle_err(self, ret, "shutdown is not successful.");
				}
			}
			sssl_write_to_so(ssl);
		}
		// 内部判断ssl链接是断开
	}
	return wb_list_pop(ssl->l);
}

int
sssl_send(struct sssl_ctx *self, int idx, const char *buf, int sz) {
	assert(idx >= 0 && idx < MAX_SSL_NUM);
	struct sssl *ssl = &self->e[idx];
	if (ssl->state != SSSL_CONNECTED) {
		return -1;
	}
	if (ssl->xsend > 0) {
		return -1;
	}
	if (buf == NULL || sz <= 0) {
		return -1;
	}
	assert(buf != NULL && sz > 0);
	int w = 0;
	for (; w < sz;) {
		int tw = SSL_write(ssl, buf + w, sz - w);
		if (tw <= 0) {
			ssl->state = SSSL_ERROR;
			sssl_handle_err(self, tw, "SSL_write error.");
			return tw;
		}
		w += tw;
	}

	// 写入数据成功，把数据发送出去
	assert(w == sz);
	return w;
}

int
sssl_recv(struct sssl_ctx *self, int idx, const char *buf, int sz) {
	assert(idx >= 0 && idx < MAX_SSL_NUM);
	struct sssl *ssl = &self->e[idx];

	int lr = 0;
	for (; lr < sz; ) {
		int nread = SSL_read(ssl->ssl, buf + lr, sz - lr);
		if (nread <= 0) {
			sssl_handle_err(self, nread, "sssl read data, BIO_read error.");
			return nread;
		}
		lr += nread;
	}

	printf("sssl read data length: %d bytes\r\n", lr);
	return lr;
}

int
sssl_get_state(struct sssl_ctx *self, int idx) {
	assert(idx >= 0 && idx < MAX_SSL_NUM);
	struct sssl *ssl = &self->e[idx];
	return ssl->state;
}

int
sssl_shutdown(struct sssl_ctx *self, int idx, int how) {
	assert(how > 0);
	assert(idx >= 0 && idx < MAX_SSL_NUM);
	struct sssl *ssl = &self->e[idx];

	if (ssl->state == SSSL_CLOSE) {
		return 0;
	}
	if (how == 1) {
		SSL_set_shutdown(ssl->ssl, SSL_SENT_SHUTDOWN);
		ssl->xsend = 1;
	} else if (how == 2) {
		SSL_set_shutdown(ssl->ssl, SSL_RECEIVED_SHUTDOWN);
		ssl->xrecv = 1;
	} else if (how == 3) {
		SSL_set_shutdown(ssl->ssl, SSL_SENT_SHUTDOWN);
		SSL_set_shutdown(ssl->ssl, SSL_RECEIVED_SHUTDOWN);
		ssl->xsend = 1;
		ssl->xrecv = 1;
	} else {
		assert(0);
	}

	SSL_shutdown(ssl->ssl);
	return 0;
}

int
sssl_close(struct sssl_ctx *self, int idx) {
	assert(idx >= 0 && idx < MAX_SSL_NUM);
	struct sssl *ssl = &self->e[idx];

	if (ssl->state == SSSL_CLOSE) {
		return 0;
	}
	ssl->state == SSSL_CLOSE;
	SSL_clear(ssl->ssl);
}
