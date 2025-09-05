#pragma once

#include <wincrypt.h>
#include <stdint.h>
#include <string>
#include "include/rtc/engine_interface.h"


// Secur32.lib
class ARTCTools
{
public:
	ARTCTools();
	~ARTCTools();

	static std::string CStringtoStdString(const CString &cs)
	{
#ifdef _UNICODE
		USES_CONVERSION;
		std::string s(W2A(cs));
		return s;
#else
		std::string s(cs.GetBuffer());
		cs.ReleaseBuffer();
		return s;
#endif
	}

	static CString AliStringToCString(const AliRTCSdk::String &s)
	{
		const char *p = s.c_str();
		int plen = strlen(p);

		int n = MultiByteToWideChar(CP_UTF8, 0, p, plen, NULL, 0);

		if (n == 0)
			return CString();

		wchar_t *buf = (wchar_t *)malloc((n + 1) * sizeof(wchar_t));

		MultiByteToWideChar(CP_UTF8, 0, p, plen, buf, n);
		buf[n] = 0;

		CString ret(buf);
		free(buf);
		return ret;
	}

	static int encoder_SHA256(const char * data, char * outBuffer) {

		HCRYPTPROV hProv = NULL;
		HCRYPTHASH hHash = NULL;

		DWORD testDataLen = strlen(data);

		// CryptAcquireContext(hProv, NULL, MS_ENH_RSA_AES_PROV, PROV_RSA_AES, 0);
		if (!CryptAcquireContext(&hProv, NULL, MS_ENH_RSA_AES_PROV, PROV_RSA_AES, CRYPT_VERIFYCONTEXT)) {
			return -1;
		}

		if (!CryptCreateHash(hProv, CALG_SHA_256, 0, 0, &hHash)) {
			char buffer[128];
			snprintf(buffer, 100, "CryptCreateHash no support SHA 256 Error: %d\n", GetLastError());
			OutputDebugStringA(buffer);
			CryptReleaseContext(hProv, 0);
			return -1;
		}

		if (!CryptHashData(hHash, (const byte *)data, testDataLen, 0)) {
			CryptDestroyHash(hHash);
			CryptReleaseContext(hProv, 0);
			return -1;
		}

		DWORD dwHashSize = 0;

		if (!CryptGetHashParam(hHash, HP_HASHVAL, NULL, &dwHashSize, 0)) {
			CryptDestroyHash(hHash);
			CryptReleaseContext(hProv, 0);
			return -1;
		}

		uint8_t hash_buffer[64];
		if (!CryptGetHashParam(hHash, HP_HASHVAL, hash_buffer, &dwHashSize, 0)) {
			CryptDestroyHash(hHash);
			CryptReleaseContext(hProv, 0);
			return -1;
		}

		for (uint32_t i = 0; i < 32; ++i) {
			outBuffer += snprintf(outBuffer, 16, "%.2x", hash_buffer[i]);
		}

		CryptDestroyHash(hHash);
		CryptReleaseContext(hProv, 0);
		return 0;

	}
};

