// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#if !TARGET_OS_TV

 #import "FBSDKSKAdNetworkConversionConfiguration.h"
 #import "FBSDKSKAdNetworkRule.h"
 #import "FBSDKTestCase.h"
 #import "FBSDKTypeUtility.h"

@interface FBSDKSKAdNetworkConversionConfiguration ()

+ (nullable NSArray<FBSDKSKAdNetworkRule *> *)parseRules:(nullable NSArray<id> *)rules;

@end

@interface FBSDKSKAdNetworkConversionConfigurationTests : FBSDKTestCase

@end

@implementation FBSDKSKAdNetworkConversionConfigurationTests

- (void)setUp
{
  [super setUp];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testInit
{
  // Init with nil
  FBSDKSKAdNetworkConversionConfiguration *config = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:nil];
  XCTAssertNil(config);

  // Init with invalid data
  id invalidData = @[];
  config = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:(NSDictionary *)invalidData];
  XCTAssertNil(config);

  invalidData = @{
    @"data" : @[@{
                  @"timer_buckets" : @(1),
                  @"timer_interval" : @(1000),
                  @"default_currency" : @"usd",
                  @"cutoff_time" : @(2),
    }]
  };
  config = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:(NSDictionary *)invalidData];
  XCTAssertNil(config);

  invalidData = @{
    @"data" : @[@{
                  @"timer_buckets" : @(1),
                  @"timer_interval" : @(1000),
                  @"cutoff_time" : @(2),
                  @"conversion_value_rules" : @[],
    }]
  };
  config = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:(NSDictionary *)invalidData];
  XCTAssertNil(config);

  // Init with valid data
  NSDictionary<NSString *, id> *validData = @{
    @"data" : @[@{
                  @"timer_buckets" : @(1),
                  @"timer_interval" : @(1000),
                  @"default_currency" : @"usd",
                  @"cutoff_time" : @(2),
                  @"conversion_value_rules" : @[],
    }]
  };
  config = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:validData];
  XCTAssertEqual(1, config.timerBuckets);
  XCTAssertEqual(2, config.cutoffTime);
  XCTAssertTrue([config.defaultCurrency isEqualToString:@"USD"]);
  XCTAssertEqualWithAccuracy(1000, config.timerInterval, 0.001);
}

- (void)testParseRules
{
  NSArray<NSDictionary<NSString *, id> *> *rules = @[
    @{
      @"conversion_value" : @(2),
      @"events" : @[
        @{
          @"event_name" : @"fb_mobile_purchase",
        }
      ],
    },
    @{
      @"conversion_value" : @(4),
      @"events" : @[
        @{
          @"event_name" : @"fb_mobile_purchase",
          @"values" : @[
            @{
              @"currency" : @"USD",
              @"amount" : @(100)
            }
          ]
        }
      ],
    },
    @{
      @"conversion_value" : @(3),
      @"events" : @[
        @{
          @"event_name" : @"fb_mobile_purchase",
          @"values" : @[
            @{
              @"currency" : @"USD",
              @"amount" : @(100)
            },
            @{
              @"currency" : @"JPY",
              @"amount" : @(100)
            }
          ]
        }
      ],
    },
  ];

  NSArray<FBSDKSKAdNetworkRule *> *conversionBitRules = [FBSDKSKAdNetworkConversionConfiguration parseRules:rules];
  NSMutableArray<FBSDKSKAdNetworkRule *> *expected = [NSMutableArray new];
  [FBSDKTypeUtility array:expected addObject:[[FBSDKSKAdNetworkRule alloc] initWithJSON:@{
                                                @"conversion_value" : @(4),
                                                @"events" : @[
                                                  @{
                                                    @"event_name" : @"fb_mobile_purchase",
                                                    @"values" : @[
                                                      @{
                                                        @"currency" : @"USD",
                                                        @"amount" : @(100)
                                                      }
                                                    ]
                                                  }
                                                ],
   }]];
  [FBSDKTypeUtility array:expected addObject:[[FBSDKSKAdNetworkRule alloc] initWithJSON:@{
                                                @"conversion_value" : @(3),
                                                @"events" : @[
                                                  @{
                                                    @"event_name" : @"fb_mobile_purchase",
                                                    @"values" : @[
                                                      @{
                                                        @"currency" : @"USD",
                                                        @"amount" : @(100)
                                                      },
                                                      @{
                                                        @"currency" : @"JPY",
                                                        @"amount" : @(100)
                                                      }
                                                    ]
                                                  }
                                                ],
   }]];
  [FBSDKTypeUtility array:expected addObject:[[FBSDKSKAdNetworkRule alloc] initWithJSON:@{
                                                @"conversion_value" : @(2),
                                                @"events" : @[
                                                  @{
                                                    @"event_name" : @"fb_mobile_purchase",
                                                  }
                                                ],
   }]];
  for (NSUInteger i = 0; i < expected.count; i++) {
    FBSDKSKAdNetworkRule *expectedRule = [FBSDKTypeUtility array:expected objectAtIndex:i];
    FBSDKSKAdNetworkRule *parsedRule = [FBSDKTypeUtility array:conversionBitRules objectAtIndex:i];
    XCTAssertNotNil(parsedRule);
    XCTAssertEqual(expectedRule.conversionValue, parsedRule.conversionValue);
    XCTAssertEqual(expectedRule.events.count, parsedRule.events.count);
    for (NSUInteger j = 0; j < expectedRule.events.count; j++) {
      FBSDKSKAdNetworkEvent *expectedEvent = [FBSDKTypeUtility array:expectedRule.events objectAtIndex:j];
      FBSDKSKAdNetworkEvent *parsedEvent = [FBSDKTypeUtility array:parsedRule.events objectAtIndex:j];
      XCTAssertTrue([expectedEvent.eventName isEqualToString:parsedEvent.eventName]);
      if (expectedEvent.values) {
        XCTAssertTrue([expectedEvent.values isEqualToDictionary:parsedEvent.values]);
      } else {
        XCTAssertNil(parsedEvent.values);
      }
    }
  }

  // Invalid cases
  id invalidData = nil;
  XCTAssertNil([FBSDKSKAdNetworkConversionConfiguration parseRules:invalidData]);
  invalidData = @{};
  XCTAssertNil([FBSDKSKAdNetworkConversionConfiguration parseRules:invalidData]);
  invalidData = @[
    @{
      @"conversion_value" : @(2),
      @"events" : @[
        @{
          @"event_name" : @"fb_mobile_purchase",
          @"values" : @[
            @{
              @"amount" : @(100)
            },
          ]
        }
      ],
    },
    @{
      @"conversion_value" : @(3),
      @"events" : @[
        @{
          @"event_name" : @"fb_mobile_purchase",
          @"values" : @[
            @{
              @"currency" : @"USD",
              @"amount" : @(100)
            },
          ]
        }
      ],
    },
  ];
  XCTAssertEqual(1, [FBSDKSKAdNetworkConversionConfiguration parseRules:invalidData].count);
}

- (void)testEventSet
{
  NSDictionary<NSString *, id> *data = @{
    @"data" : @[@{
                  @"timer_buckets" : @(1),
                  @"timer_interval" : @(1000),
                  @"cutoff_time" : @(2),
                  @"default_currency" : @"usd",
                  @"conversion_value_rules" : @[
                    @{
                      @"conversion_value" : @(2),
                      @"events" : @[
                        @{
                          @"event_name" : @"fb_mobile_purchase",
                        }
                      ],
                    },
                    @{
                      @"conversion_value" : @(4),
                      @"events" : @[
                        @{
                          @"event_name" : @"fb_mobile_purchase",
                          @"values" : @[
                            @{
                              @"currency" : @"USD",
                              @"amount" : @(100)
                            }
                          ]
                        },
                        @{
                          @"event_name" : @"fb_mobile_complete_registration",
                          @"values" : @[
                            @{
                              @"currency" : @"EU",
                              @"amount" : @(100)
                            }
                          ]
                        },
                      ],
                    },
                    @{
                      @"conversion_value" : @(3),
                      @"events" : @[
                        @{
                          @"event_name" : @"fb_mobile_purchase",
                          @"values" : @[
                            @{
                              @"currency" : @"USD",
                              @"amount" : @(100)
                            },
                            @{
                              @"currency" : @"JPY",
                              @"amount" : @(100)
                            }
                          ]
                        },
                        @{
                          @"event_name" : @"fb_mobile_search",
                        }
                      ],
                    },
                  ]
    }]
  };

  FBSDKSKAdNetworkConversionConfiguration *config = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:data];
  NSSet<NSString *> *expected = [NSSet setWithArray:@[@"fb_mobile_search", @"fb_mobile_purchase", @"fb_mobile_complete_registration"]];
  XCTAssertTrue([config.eventSet isEqualToSet:expected]);
}

- (void)testCurrencySet
{
  NSDictionary<NSString *, id> *data = @{
    @"data" : @[@{
                  @"timer_buckets" : @(1),
                  @"timer_interval" : @(1000),
                  @"cutoff_time" : @(2),
                  @"default_currency" : @"usd",
                  @"conversion_value_rules" : @[
                    @{
                      @"conversion_value" : @(2),
                      @"events" : @[
                        @{
                          @"event_name" : @"fb_mobile_purchase",
                        }
                      ],
                    },
                    @{
                      @"conversion_value" : @(4),
                      @"events" : @[
                        @{
                          @"event_name" : @"fb_mobile_purchase",
                          @"values" : @[
                            @{
                              @"currency" : @"USD",
                              @"amount" : @(100)
                            }
                          ]
                        },
                        @{
                          @"event_name" : @"fb_mobile_complete_registration",
                          @"values" : @[
                            @{
                              @"currency" : @"eu",
                              @"amount" : @(100)
                            }
                          ]
                        },
                      ],
                    },
                    @{
                      @"conversion_value" : @(3),
                      @"events" : @[
                        @{
                          @"event_name" : @"fb_mobile_purchase",
                          @"values" : @[
                            @{
                              @"currency" : @"usd",
                              @"amount" : @(100)
                            },
                            @{
                              @"currency" : @"jpy",
                              @"amount" : @(100)
                            }
                          ]
                        },
                        @{
                          @"event_name" : @"fb_mobile_search",
                        }
                      ],
                    },
                  ]
    }]
  };

  FBSDKSKAdNetworkConversionConfiguration *config = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:data];
  NSSet<NSString *> *expected = [NSSet setWithArray:@[@"USD", @"EU", @"JPY"]];
  XCTAssertTrue([config.currencySet isEqualToSet:expected]);
}

@end

#endif
