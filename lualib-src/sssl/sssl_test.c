#include "sssl_test.h"
#include "stringx.h"
#include "urlparser.h"
#include "sssl.h"

#if defined(WIN32) || defined(WIN64)
//#include <Windows.h>
#include <Winsock2.h>
#include <Wininet.h>
#include <ws2tcpip.h>
#pragma comment (lib, "Ws2_32.lib")
#else
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <sys/timeb.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#endif

#include "uthash.h"

#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <time.h>
#include <assert.h>
#include <errno.h>


///*
//	Handles redirect if needed for get requests
//*/
//struct http_response* handle_redirect_get(struct http_response* hresp, char* custom_headers) {
//	if (hresp->status_code_int > 300 && hresp->status_code_int < 399) {
//		char *token = strtok(hresp->response_headers, "\r\n");
//		while (token != NULL) {
//			if (str_contains(token, "Location:")) {
//				/* Extract url */
//				char *location = str_replace("Location: ", "", token);
//				return http_get(location, custom_headers);
//			}
//			token = strtok(NULL, "\r\n");
//		}
//	} else {
//		/* We're not dealing with a redirect, just return the same structure */
//		return hresp;
//	}
//}
//
///*
//	Handles redirect if needed for head requests
//*/
//struct http_response* handle_redirect_head(struct http_response* hresp, char* custom_headers) {
//	if (hresp->status_code_int > 300 && hresp->status_code_int < 399) {
//		char *token = strtok(hresp->response_headers, "\r\n");
//		while (token != NULL) {
//			if (str_contains(token, "Location:")) {
//				/* Extract url */
//				char *location = str_replace("Location: ", "", token);
//				return http_head(location, custom_headers);
//			}
//			token = strtok(NULL, "\r\n");
//		}
//	} else {
//		/* We're not dealing with a redirect, just return the same structure */
//		return hresp;
//	}
//}
//
///*
//	Handles redirect if needed for post requests
//*/
//struct http_response* handle_redirect_post(struct http_response* hresp, char* custom_headers, char *post_data) {
//	if (hresp->status_code_int > 300 && hresp->status_code_int < 399) {
//		char *token = strtok(hresp->response_headers, "\r\n");
//		while (token != NULL) {
//			if (str_contains(token, "Location:")) {
//				/* Extract url */
//				char *location = str_replace("Location: ", "", token);
//				return http_post(location, custom_headers, post_data);
//			}
//			token = strtok(NULL, "\r\n");
//		}
//	} else {
//		/* We're not dealing with a redirect, just return the same structure */
//		return hresp;
//	}
//}

static int
sssl_callback(void *ud, const char * cmd, int how) {
	/*if (strcmp(cmd, 'S') == 0) {
		struct ssock *so = (struct ssock *)ud;
		shutdown(so->fd, how);
	} else if (strcmp(cmd, 'K') == 0) {
		struct ssock *so = (struct ssock *)ud;
		closesocket(so->fd);
	}*/
	return 0;
}

struct ssock *
ssock_alloc() {
#if defined(_WIN32)
	WSADATA wsaData;
	int iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
	if (iResult != 0) {
		printf("WSAStartup failture.");
	}
#endif
	struct ssock *inst = (struct ssock *)malloc(sizeof(*inst));
	memset(inst, 0, sizeof(*inst));
	inst->sssl = sssl_alloc(inst, sssl_callback);
	return inst;
}

void
ssock_free(struct ssock *self) {
	sssl_free(self->sssl);
	free(self);
#if defined(_WIN32)
	WSACleanup();
#endif // defined(_WIN32)
}

int
ssock_connect(struct ssock *self, const char *addr, int port) {
	int idx = 0;
	int fd = 0;
	if ((fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) == -1) {
		printf("创建socket 失败.");
		exit(0);
	}
	printf("创建套接字成功\r\n"); 
	self->fds[idx] = fd;
	self->state[idx] = SSOCK_CLOSE;

	struct sockaddr_in add;
	add.sin_family = AF_INET;
	if (inet_pton(AF_INET, addr, &add.sin_addr) < 0) {
		return -1;
	}
	add.sin_port = htons(port);
	int res = connect(fd, (struct sockaddr *)&add, sizeof(add));
	if (res < 0) {
#ifdef _WIN32
		int err = WSAGetLastError();
		if (err == EWOULDBLOCK) {

		}
#endif // _WIN32
		return -1;
	}
	printf("socket 链接成功\r\n");
	self->ssslidx[idx] = sssl_connect(self->sssl, addr, port);
	return idx;
}

int
ssock_update(struct ssock *self) {
	int max = 0;
	for (size_t i = 0; i < 1; i++) {

	}
	for (size_t i = 0; i < 1; i++) {
		char buf[4096] = { 0 };
		int nread = recv(self->fds[i], buf, 4096, 0);
		if (nread > 0) {
			struct write_buffer *wb = sssl_poll(self->sssl, 0, buf, nread);
			send(self->fds[i], wb->ptr, wb->len, 0);
		} else if (nread == 0) {
			// 断联
		} else if (nread < 0) {
			// 出错
			if (nread == WSAEWOULDBLOCK) {
				struct write_buffer *wb = sssl_poll(self->sssl, 0, buf, 0);
				send(self->fds[i], wb->ptr, wb->len, 0);
			}
		}
		// recv
		sssl_recv(self->sssl, self->ssslidx[i], buf, 4096);
		printf(buf);
	}
	return 0;
}

struct http_response*
ssock_req(struct ssock *self, char *http_headers, struct parsed_url *purl) {
	/* Parse url */
	if (purl == NULL) {
		printf("Unable to parse url");
		return NULL;
	}

	/* Declare variable */
	int sock;
	int tmpres;
	char buf[BUFSIZ + 1];
	struct sockaddr_in *remote;

	/* Allocate memeory for htmlcontent */
	struct http_response *hresp = (struct http_response*)malloc(sizeof(struct http_response));
	if (hresp == NULL) {
		printf("Unable to allocate memory for htmlcontent.");
		return NULL;
	}
	hresp->body = NULL;
	hresp->request_headers = NULL;
	hresp->response_headers = NULL;
	hresp->status_code = NULL;
	hresp->status_text = NULL;

	/* Create TCP socket */
	if ((sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
		printf("Can't create TCP socket");
		return NULL;
	}

	/* Set remote->sin_addr.s_addr */
	remote = (struct sockaddr_in *)malloc(sizeof(struct sockaddr_in *));
	remote->sin_family = AF_INET;
	tmpres = inet_pton(AF_INET, purl->ip, (void *)(&(remote->sin_addr.s_addr)));
	if (tmpres < 0) {
		printf("Can't set remote->sin_addr.s_addr");
		return NULL;
	} else if (tmpres == 0) {
		printf("Not a valid IP");
		return NULL;
	}
	remote->sin_port = htons(atoi(purl->port));

	/* Connect */
	if (connect(sock, (struct sockaddr *)remote, sizeof(struct sockaddr)) < 0) {
		printf("Could not connect");
		return NULL;
	}

	/* ssl */
	struct sssl_ctx *ssl = sssl_alloc(NULL, sssl_callback);
	int idx = -1;
	if (idx = sssl_connect(ssl, (const char *)purl->ip, purl->port) < 0) {
		printf("Could not connect");
	}

	char BUF[BUFSIZ];
	int nrecv = 0;
	/*  */
	while (1) {
		char RAWBUF[BUFSIZ];
		size_t recived_len = recv(sock, RAWBUF, BUFSIZ - 1, 0);
		if (recived_len > 0) {
			struct write_buffer *wb = sssl_poll(ssl, idx, BUF, recived_len);
			send(sock, wb->ptr, wb->len, 0);
		} else {
			struct write_buffer *wb = sssl_poll(ssl, idx, NULL, 0);
			send(sock, wb->ptr, wb->len, 0);
		}
		if (sssl_get_state(ssl, idx) == SSSL_CONNECTED) {
			for (size_t i = 0; i < 1; i++) {
				int sent = 0;
				while (sent < strlen(http_headers)) {
					tmpres = sssl_send(ssl, idx, http_headers + sent, strlen(http_headers) - sent);
					if (tmpres == -1) {
						printf("Can't send headers");
						return NULL;
					}
					sent += tmpres;
				}
			}
			int n = 0;
			if (n = nrecv = sssl_recv(ssl, idx, BUF, BUFSIZ - 1) > 0) {
				nrecv += n;
			} else {
				break;
			}

		} else {
			sssl_recv(ssl, idx, BUF, BUFSIZ - 1);
		}
	}

	/* Send headers to server */
	/*int sent = 0;
	while(sent < strlen(http_headers))
	{
		tmpres = send(sock, http_headers+sent, strlen(http_headers)-sent, 0);
		if(tmpres == -1)
		{
			printf("Can't send headers");
			return NULL;
		}
		sent += tmpres;
	 }*/

	 /* Recieve into response*/
	char *response = (char*)malloc(0);
	/*char BUF[BUFSIZ];
	size_t recived_len = 0;
	while ((recived_len = recv(sock, BUF, BUFSIZ - 1, 0)) > 0) {
		BUF[recived_len] = '\0';
		response = (char*)realloc(response, strlen(response) + strlen(BUF) + 1);
		sprintf(response, "%s%s", response, BUF);
	}
	if (recived_len < 0) {
		free(http_headers);
#ifdef _WIN32
		closesocket(sock);
#else
		close(sock);
#endif
		printf("Unabel to recieve");
		return NULL;
	}*/


	/* Reallocate response */
	response = (char*)realloc(response, strlen(response) + 1);

	/* Close socket */
#ifdef _WIN32
	closesocket(sock);
#else
	close(sock);
#endif

	/* Parse status code and text */
	char *status_line = get_until(response, "\r\n");
	status_line = str_replace("HTTP/1.1 ", "", status_line);
	char *status_code = str_ndup(status_line, 4);
	status_code = str_replace(" ", "", status_code);
	char *status_text = str_replace(status_code, "", status_line);
	status_text = str_replace(" ", "", status_text);
	hresp->status_code = status_code;
	hresp->status_code_int = atoi(status_code);
	hresp->status_text = status_text;

	/* Parse response headers */
	char *headers = get_until(response, "\r\n\r\n");
	hresp->response_headers = headers;

	/* Assign request headers */
	hresp->request_headers = http_headers;

	/* Assign request url */
	hresp->request_uri = purl;

	/* Parse body */
	char *body = strstr(response, "\r\n\r\n");
	body = str_replace("\r\n\r\n", "", body);
	hresp->body = body;

	/* Return response */
	return hresp;

}

struct http_response*
ssock_get(struct ssock *self, char *url, char *custom_headers) {
	/* Parse url */
	struct parsed_url *purl = parse_url(url);
	if (purl == NULL) {
		printf("Unable to parse url");
		return NULL;
	}

	/* Declare variable */
	char *http_headers = (char*)malloc(1024);

	/* Build query/headers */
	if (purl->path != NULL) {
		if (purl->query != NULL) {
			sprintf(http_headers, "GET /%s?%s HTTP/1.1\r\nHost:%s\r\nConnection:close\r\n", purl->path, purl->query, purl->host);
		} else {
			sprintf(http_headers, "GET /%s HTTP/1.1\r\nHost:%s\r\nConnection:close\r\n", purl->path, purl->host);
		}
	} else {
		if (purl->query != NULL) {
			sprintf(http_headers, "GET /?%s HTTP/1.1\r\nHost:%s\r\nConnection:close\r\n", purl->query, purl->host);
		} else {
			sprintf(http_headers, "GET / HTTP/1.1\r\nHost:%s\r\nConnection:close\r\n", purl->host);
		}
	}

	/* Handle authorisation if needed */
	if (purl->username != NULL) {
		/* Format username:password pair */
		char *upwd = (char*)malloc(1024);
		sprintf(upwd, "%s:%s", purl->username, purl->password);
		upwd = (char*)realloc(upwd, strlen(upwd) + 1);

		/* Base64 encode */
		char *base64 = base64_encode(upwd);

		/* Form header */
		char *auth_header = (char*)malloc(1024);
		sprintf(auth_header, "Authorization: Basic %s\r\n", base64);
		auth_header = (char*)realloc(auth_header, strlen(auth_header) + 1);

		/* Add to header */
		http_headers = (char*)realloc(http_headers, strlen(http_headers) + strlen(auth_header) + 2);
		sprintf(http_headers, "%s%s", http_headers, auth_header);
	}

	/* Add custom headers, and close */
	if (custom_headers != NULL) {
		sprintf(http_headers, "%s%s\r\n", http_headers, custom_headers);
	} else {
		sprintf(http_headers, "%s\r\n", http_headers);
	}
	http_headers = (char*)realloc(http_headers, strlen(http_headers) + 1);

	/* Make request and return response */
	struct http_response *hresp = ssock_req(self, http_headers, purl);

	/* Handle redirect */
	//return handle_redirect_get(hresp, custom_headers);
	return NULL;
}

struct http_response*
ssock_head(struct ssock *self, char *url, char *custom_headers) {
	return NULL;
}

struct http_response*
ssock_post(struct ssock *self, char *url, char *custom_headers, char *post_data) {
	return NULL;
}

int
ssock_shutdown(struct ssock *self, int how) {
	//return sssl_shutdown(self->sssl, how);
	return 0;
}

int
ssock_close(struct ssock *self) {
	//return sssl_close(self->sssl);
	return 0;
}

int
ssock_clear(struct ssock *self) {
	//return sssl_clear(self->sssl);
	return 0;
}


int
main(int argv, char **argc) {
	struct ssock * so = ssock_alloc();
	struct http_response* resp = ssock_get(so, "https://www.baidu.com:443", NULL);
	return 0;
}