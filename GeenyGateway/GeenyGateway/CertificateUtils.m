//
//  CertificateUtils.m
//  sign
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

#import "CertificateUtils.h"

#include <stdio.h>
#include <stdlib.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/pkcs12.h>

#import "fmemopen.h"

@implementation CertificateUtils

#pragma mark - Private Key Encryption

+ (NSString *)encryptPrivateKey:(NSString *)privateKey withPassword:(NSString *)password {
  // Initialize
  OpenSSL_add_all_algorithms();
  ERR_load_crypto_strings();
  
  // Read private key
  const char *cPrivateKey = [privateKey UTF8String];
  FILE *privateKeyFile = fmemopen((void *)cPrivateKey, sizeof(char) * (privateKey.length + 1), "r");
  EVP_PKEY *pKey = PEM_read_PrivateKey(privateKeyFile, NULL, NULL, NULL);
  fclose(privateKeyFile);
  
  // Write out encrypted key
  const EVP_CIPHER *pCipher = EVP_aes_256_cbc();
  char *cPassword = (char *)[password UTF8String];
  int length = (int)[password length];
  BIO *outBio = BIO_new(BIO_s_mem());
  PEM_write_bio_PKCS8PrivateKey(outBio, pKey, pCipher, cPassword, (int)length, NULL, NULL);
  
  char *bytePointer;
  int bioLength = (int) BIO_ctrl(outBio, BIO_CTRL_INFO, 0, (char *)&bytePointer);
  NSData *data = [NSData dataWithBytes:bytePointer length:bioLength];
  BIO_free(outBio);
  NSString *outString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  
  // Clean up
  EVP_cleanup();
  ERR_free_strings();
  
  return outString;
}

#pragma mark - P12 Generation

// infile: concatenated text file with
// - CACertificate (optional)
// - ClientCertificate, and
// - PrivateKey
+ (BOOL)createP12FileWithPath:(NSString *)outPath certificatePath:(NSString *)inPath name:(NSString *)name password:(NSString *)password {
  SSLeay_add_all_algorithms();
  ERR_load_crypto_strings();
  
  FILE *fp;
  if (!(fp = fopen([inPath UTF8String], "r"))) {
    NSLog(@"Error opening file %@\n", inPath);
    return NO;
  }
  
  X509 *cert = PEM_read_X509(fp, NULL, NULL, NULL);
  rewind(fp);
  EVP_PKEY *pkey = PEM_read_PrivateKey(fp, NULL, NULL, NULL);
  fclose(fp);
  
  char *cPassword = (char *)[password UTF8String];
  char *cName = (char *)[name UTF8String];
  
  PKCS12 *p12 = PKCS12_create(cPassword, cName, pkey, cert, NULL, 0,0,0,0,0);
  if (!p12) {
    NSLog(@"Error creating PKCS#12 structure");
    ERR_print_errors_fp(stderr);
    return NO;
  }
    
  if (!(fp = fopen([outPath UTF8String], "wb"))) {
    NSLog(@"Error opening file %@\n", outPath);
    ERR_print_errors_fp(stderr);
    return NO;
  }
  i2d_PKCS12_fp(fp, p12);
  PKCS12_free(p12);
  fclose(fp);
  
  return YES;
}

+ (NSData *)createP12DataWithCertificate:(NSString *)certificate privateKey:(NSString *)privateKey name:(NSString *)name password:(NSString *)password {
  SSLeay_add_all_algorithms();
  ERR_load_crypto_strings();
  
  NSString *content = [certificate stringByAppendingString:privateKey];
  
  // Read certificate
  const char *certificateChar = [content UTF8String];
  FILE *certificateFile = fmemopen((void *)certificateChar, sizeof(char) * (content.length + 1), "r");
  X509 *cert = PEM_read_X509(certificateFile, NULL, NULL, NULL);
  rewind(certificateFile);
  
  // Read private key
  EVP_PKEY *pkey = PEM_read_PrivateKey(certificateFile, NULL, NULL, NULL);
  fclose(certificateFile);
  
  // Generate P12
  char *cPassword = (char *)[password UTF8String];
  char *cName = (char *)[name UTF8String];
  
  PKCS12 *p12 = PKCS12_create(cPassword, cName, pkey, cert, NULL, 0,0,0,0,0);
  if (!p12) {
    NSLog(@"Error creating PKCS#12 structure");
    ERR_print_errors_fp(stderr);
    return nil;
  }
  
  // Convert to NSData
  BIO *outBio = BIO_new(BIO_s_mem());
  i2d_PKCS12_bio(outBio, p12);
  
  char *bytePointer;
  int length = (int) BIO_ctrl(outBio, BIO_CTRL_INFO, 0, (char *)&bytePointer);
  NSData *data = [NSData dataWithBytes:bytePointer length:length];
  
  BIO_free(outBio);
  PKCS12_free(p12);

  return data;
}

@end
