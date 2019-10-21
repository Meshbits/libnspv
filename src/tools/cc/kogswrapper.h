
/******************************************************************************
 * Copyright � 2014-2019 The SuperNET Developers.                             *
 *                                                                            *
 * See the AUTHORS, DEVELOPER-AGREEMENT and LICENSE files at                  *
 * the top-level directory of this distribution for the individual copyright  *
 * holder information and the developer policies on copyright and licensing.  *
 *                                                                            *
 * Unless otherwise agreed in a custom licensing agreement, no part of the    *
 * SuperNET software, including this file may be copied, modified, propagated *
 * or distributed except according to the terms contained in the LICENSE file *
 *                                                                            *
 * Removal or modification of this copyright notice is prohibited.            *
 *                                                                            *
 ******************************************************************************/

#ifndef __KOGSWRAPPER_H__
#define __KOGSWRAPPER_H__

#include <btc/btc.h>

#ifndef LIBNSPV_API
#if defined(_WIN32)
#ifdef LIBNSPV_BUILD
#define LIBNSPV_API __declspec(dllexport)
#else
#define LIBNSPV_API
#endif
#elif defined(__GNUC__) && defined(LIBNSPV_BUILD)
#define LIBNSPV_API __attribute__((visibility("default")))
#else
#define LIBNSPV_API
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

    // kogs wrapper functions:
    int32_t __stdcall LIBNSPV_API LibNSPVSetup(char *chainname, char *errorstr);
    int32_t __stdcall LIBNSPV_API CCKogsList(uint256 **plist, int32_t *pcount, char *errorstr);

    void __stdcall LIBNSPV_API CCWrapperFree(void *ptr);
    void __stdcall LIBNSPV_API LibNSPVFinish();

#ifdef __cplusplus
}
#endif

#endif // #ifndef __KOGSWRAPPER_H__