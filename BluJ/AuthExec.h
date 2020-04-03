//
//  AuthExec.h
//  BluJ
//
//  Created by Lavergne, Marc on 3/23/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

#ifndef AuthExec_h
#define AuthExec_h

#import <Foundation/Foundation.h>

@interface AuthExec : NSObject

/**
 * The application *cannot* be  sandboxed  for this to work since executable paths are not available in the sandbox
 */
+ (OSStatus)execute:(AuthorizationRef)authorizationRef executable:(NSString *)tool args:(NSArray<NSString *> *)args;

@end

#endif /* AuthExec_h */
