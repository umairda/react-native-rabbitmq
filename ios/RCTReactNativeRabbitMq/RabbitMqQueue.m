#import "RabbitMqQueue.h"

@interface RabbitMqQueue ()
    @property (nonatomic, readwrite) NSString *name;
    @property (nonatomic, readwrite) NSDictionary *config;
    @property (nonatomic, readwrite) RMQQueue *queue; 
    @property (nonatomic, readwrite) id<RMQChannel> channel;
    @property (nonatomic, readwrite) RMQQueueDeclareOptions options;
    @property (nonatomic, readwrite) RCTBridge *bridge;
@end

@implementation RabbitMqQueue


RCT_EXPORT_MODULE();

-(id)initWithConfig:(NSDictionary *)config channel:(id<RMQChannel>)channel bridge:(RCTBridge *)bridge {
    if (self = [super init]) {

        self.config = config;
        self.channel = channel;
        self.name = [config objectForKey:@"name"];
        self.bridge = bridge;

        self.options = RMQQueueDeclareNoOptions;
    
        if ([config objectForKey:@"passive"] != nil && [[config objectForKey:@"passive"] boolValue]){
            self.options = self.options | RMQQueueDeclarePassive;
        }

        if ([config objectForKey:@"durable"] != nil && [[config objectForKey:@"durable"] boolValue]){
           self.options = self.options | RMQQueueDeclareDurable;
        }

        if ([config objectForKey:@"exclusive"] != nil && [[config objectForKey:@"exclusive"] boolValue]){
            self.options = self.options | RMQQueueDeclareExclusive;
        }

        if ([config objectForKey:@"autoDelete"] != nil && [[config objectForKey:@"autoDelete"] boolValue]){
            self.options = self.options | RMQExchangeDeclareAutoDelete;
        }

        if ([config objectForKey:@"NoWait"] != nil && [[config objectForKey:@"NoWait"] boolValue]){
            self.options = self.options | RMQQueueDeclareNoWait;
        }

        self.queue = [self.channel queue:self.name options:self.options];
        

        NSDictionary *tmp_arguments = @{};
        if ([config objectForKey:@"consumer_arguments"] != nil){
            NSDictionary *consumer_arguments = [config objectForKey:@"consumer_arguments"];
            if ([consumer_arguments objectForKey:@"x-priority"] != nil){
                NSNumber *xpriority = [consumer_arguments objectForKey:@"x-priority"];
                tmp_arguments = @{@"x-priority": [[RMQSignedShort alloc] init:xpriority]};
            }
        }

        RMQBasicConsumeOptions consumer_options = RMQBasicConsumeNoOptions;

        RMQTable *arguments = [[RMQTable alloc] init:tmp_arguments];

        [self.queue subscribe:consumer_options
                    arguments:arguments
                    handler:^(RMQMessage * _Nonnull message) {

            NSString *body = [[NSString alloc] initWithData:message.body encoding:NSUTF8StringEncoding];

            //[self.channel ack:message.deliveryTag];

            [self.bridge.eventDispatcher sendAppEventWithName:@"RabbitMqQueueEvent" 
                body:@{
                    @"name": @"message", 
                    @"queue_name": self.name, 
                    @"message": body, 
                    @"routingKey": message.routingKey, 
                    @"exchange": message.exchangeName,
                    @"consumer_tag": message.consumerTag, 
                    @"delivery_tag": message.deliveryTag
                }
            ];
        }];

    }
    return self;
}

-(void) bind:(RMQExchange *)exchange routing_key:(NSString *)routing_key {

  
    if ([routing_key length] == 0){
        [self.queue bind:exchange];
    }else{
        [self.queue bind:exchange routingKey:routing_key];
    }
}

-(void) unbind:(RMQExchange *)exchange routing_key:(NSString *)routing_key {

    if ([routing_key length] == 0){
        [self.queue unbind:exchange];
    }else{
        [self.queue unbind:exchange routingKey:routing_key];
    }
}

-(void) delete {
    [self.queue delete:self.options];
}

-(void) ack:(NSNumber *)deliveryTag {
    [self.channel ack:deliveryTag];
}

RCT_EXPORT_METHOD(publish:(NSData *)data
    properties:(NSArray<RMQValue<RMQBasicValue> *> *)properties
    options:(RMQBasicPublishOptions)options,
    exchange:(NSString *)exchange) {
      return [self.channel 
        basicPublish:data
        routingKey:self.name
        exchange:@exchange
        properties:properties
        options:options];
}

@end
