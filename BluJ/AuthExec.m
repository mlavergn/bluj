//
//  AuthExec.m
//  BluJ
//
//  Created by Lavergne, Marc on 3/23/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

#import "AuthExec.h"

@implementation AuthExec

/**
 *  The application *cannot* be  sandboxed  for this to work since no executable paths are in the sandbox
 */
+ (OSStatus)execute:(AuthorizationRef)authorizationRef executable:(NSString *)executable args:(NSArray<NSString *> *)args {
    char* exec = (char *)executable.UTF8String;
    const char ** argv = (const char **) alloca(sizeof(char *) * args.count + 1);
    int i = 0;
    for (; i < args.count; i++) {
        argv[i] = args[i].UTF8String;
    }
    argv[i] = NULL;
    
    FILE* pipe = NULL;

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return AuthorizationExecuteWithPrivileges(authorizationRef, exec, kAuthorizationFlagDefaults, (char *const _Nonnull * _Nonnull)argv, &pipe);
    #pragma clang diagnostic pop
}

@end
