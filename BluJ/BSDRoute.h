//
//  BSDRoute.h
//  BluJ
//
//  Created by Lavergne, Marc on 3/26/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

#ifndef BSDRoute_h
#define BSDRoute_h

#import <Foundation/Foundation.h>

#import <net/route.h>

@interface BSDRoute : NSObject
    @property (nonatomic) NSString *destination;
    @property (nonatomic) NSString *gateway;
    @property (nonatomic) NSString *netmask;

    + (NSMutableArray<BSDRoute*>*) getRoutes;
    + (BOOL) addRoute: (NSString *)ipDestination ipGateway:(NSString *)ipGateway ifName:(NSString *)ifName;
    + (BOOL) delRoute: (NSString *)ipDestination ipGateway:(NSString *)ipGateway ifName:(NSString *)ifName;
@end

#endif /* BSDRoute_h */
