/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

#include "openssl.h"

#ifdef GIT_OPENSSL_DYNAMIC
# include <dlfcn.h>

int handle_count;
void *openssl_handle;

static int git_hash_openssl_global_shutdown(void)
{
	if (--handle_count == 0) {
		dlclose(openssl_handle);
		openssl_handle = NULL;
	}

	return 0;
}

static int git_hash_openssl_global_init(void)
{
	if (!handle_count) {
		if ((openssl_handle = dlopen("libssl.so.1.1", RTLD_NOW)) == NULL &&
		    (openssl_handle = dlopen("libssl.1.1.dylib", RTLD_NOW)) == NULL &&
		    (openssl_handle = dlopen("libssl.so.1.0.0", RTLD_NOW)) == NULL &&
		    (openssl_handle = dlopen("libssl.1.0.0.dylib", RTLD_NOW)) == NULL &&
		    (openssl_handle = dlopen("libssl.so.10", RTLD_NOW)) == NULL) {
			git_error_set(GIT_ERROR_SSL, "could not load ssl libraries");
			return -1;
		}
	}

	if (git_hash_openssl_global_shutdown() < 0)
		return -1;

	handle_count++;
	return 0;
}

#endif

#ifdef GIT_SHA1_OPENSSL

# ifdef GIT_OPENSSL_DYNAMIC
static int (*SHA1_Init)(SHA_CTX *c);
static int (*SHA1_Update)(SHA_CTX *c, const void *data, size_t len);
static int (*SHA1_Final)(unsigned char *md, SHA_CTX *c);
# endif

int git_hash_sha1_global_init(void)
{
#ifdef GIT_OPENSSL_DYNAMIC
	if (git_hash_openssl_global_init() < 0)
		return -1;

	if ((SHA1_Init = dlsym(openssl_handle, "SHA1_Init")) == NULL ||
	    (SHA1_Update = dlsym(openssl_handle, "SHA1_Update")) == NULL ||
	    (SHA1_Final = dlsym(openssl_handle, "SHA1_Final")) == NULL) {
		const char *msg = dlerror();
		git_error_set(GIT_ERROR_SSL, "could not load hash function: %s", msg ? msg : "unknown error");
		return -1;
	}
#endif

	return 0;
}

int git_hash_sha1_ctx_init(git_hash_sha1_ctx *ctx)
{
	return git_hash_sha1_init(ctx);
}

void git_hash_sha1_ctx_cleanup(git_hash_sha1_ctx *ctx)
{
	GIT_UNUSED(ctx);
}

int git_hash_sha1_init(git_hash_sha1_ctx *ctx)
{
	GIT_ASSERT_ARG(ctx);

	if (SHA1_Init(&ctx->c) != 1) {
		git_error_set(GIT_ERROR_SHA, "failed to initialize sha1 context");
		return -1;
	}

	return 0;
}

int git_hash_sha1_update(git_hash_sha1_ctx *ctx, const void *data, size_t len)
{
	GIT_ASSERT_ARG(ctx);

	if (SHA1_Update(&ctx->c, data, len) != 1) {
		git_error_set(GIT_ERROR_SHA, "failed to update sha1");
		return -1;
	}

	return 0;
}

int git_hash_sha1_final(unsigned char *out, git_hash_sha1_ctx *ctx)
{
	GIT_ASSERT_ARG(ctx);

	if (SHA1_Final(out, &ctx->c) != 1) {
		git_error_set(GIT_ERROR_SHA, "failed to finalize sha1");
		return -1;
	}

	return 0;
}

#endif

#ifdef GIT_SHA256_OPENSSL

# ifdef GIT_OPENSSL_DYNAMIC
static int (*SHA256_Init)(SHA256_CTX *c);
static int (*SHA256_Update)(SHA256_CTX *c, const void *data, size_t len);
static int (*SHA256_Final)(unsigned char *md, SHA256_CTX *c);
#endif

int git_hash_sha256_global_init(void)
{
#ifdef GIT_OPENSSL_DYNAMIC
	if (git_hash_openssl_global_init() < 0)
		return -1;

	if ((SHA256_Init = dlsym(openssl_handle, "SHA256_Init")) == NULL ||
	    (SHA256_Update = dlsym(openssl_handle, "SHA256_Update")) == NULL ||
	    (SHA256_Final = dlsym(openssl_handle, "SHA256_Final")) == NULL) {
		const char *msg = dlerror();
		git_error_set(GIT_ERROR_SSL, "could not load hash function: %s", msg ? msg : "unknown error");
		return -1;
	}
#endif

	return 0;
}

int git_hash_sha256_ctx_init(git_hash_sha256_ctx *ctx)
{
	return git_hash_sha256_init(ctx);
}

void git_hash_sha256_ctx_cleanup(git_hash_sha256_ctx *ctx)
{
	GIT_UNUSED(ctx);
}

int git_hash_sha256_init(git_hash_sha256_ctx *ctx)
{
	GIT_ASSERT_ARG(ctx);

	if (SHA256_Init(&ctx->c) != 1) {
		git_error_set(GIT_ERROR_SHA, "failed to initialize sha256 context");
		return -1;
	}

	return 0;
}

int git_hash_sha256_update(git_hash_sha256_ctx *ctx, const void *data, size_t len)
{
	GIT_ASSERT_ARG(ctx);

	if (SHA256_Update(&ctx->c, data, len) != 1) {
		git_error_set(GIT_ERROR_SHA, "failed to update sha256");
		return -1;
	}

	return 0;
}

int git_hash_sha256_final(unsigned char *out, git_hash_sha256_ctx *ctx)
{
	GIT_ASSERT_ARG(ctx);

	if (SHA256_Final(out, &ctx->c) != 1) {
		git_error_set(GIT_ERROR_SHA, "failed to finalize sha256");
		return -1;
	}

	return 0;
}

#endif
