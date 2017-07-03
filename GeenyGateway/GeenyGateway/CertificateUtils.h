//
//  CertificateUtils.h
//  sign
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface CertificateUtils : NSObject

#pragma mark - Private Key Encryption

+ (NSString *)encryptPrivateKey:(NSString *)privateKey withPassword:(NSString *)password;

#pragma mark - P12 Generation

+ (BOOL)createP12FileWithPath:(NSString *)outPath certificatePath:(NSString *)inPath name:(NSString *)name password:(NSString *)password NS_SWIFT_NAME(createP12File(path:certificatePath:name:password:));

+ (nullable NSData *)createP12DataWithCertificate:(NSString *)certificate privateKey:(NSString *)privateKey name:(NSString *)name password:(NSString *)password NS_SWIFT_NAME(createP12Data(certificate:privateKey:name:password:));

@end

NS_ASSUME_NONNULL_END

