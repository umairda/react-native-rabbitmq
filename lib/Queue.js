import {DeviceEventEmitter} from 'react-native';

export class Queue {

    constructor(connection, queue_config, args) {

        this.callbacks = {};
        this.rabbitmqconnection = connection.rabbitmqconnection;

        this.name = queue_config.name;
        this.queue_config = queue_config;
        this.arguments = args || {};

        this.message_buffer = [];
        this.message_buffer_delay =  (queue_config.buffer_delay ? queue_config.buffer_delay : 1000);
        this.message_buffer_timeout = null;

        DeviceEventEmitter.addListener('RabbitMqQueueEvent', this.handleEvent);
     
        this.rabbitmqconnection.addQueue(queue_condig, this.arguments);

    }

    handleEvent = (event) => {

        if (event.queue_name != this.name){ return; }

        if (event.name == 'message'){

            if (this.queue_condig.autoBufferAck) {
                this.basicAck(event.delivery_tag);
            }

            if (this.callbacks.hasOwnProperty(event.name)){
                this.callbacks['message'](event);
            }

            if (this.callbacks.hasOwnProperty('messages')){

                this.message_buffer.push(event);

                clearTimeout(this.message_buffer_timeout);

                this.message_buffer_timeout = setTimeout(() => { 

                    if (this.message_buffer.length > 0){
                        if (this.callbacks.hasOwnProperty('messages')){
                            this.callbacks['messages'](this.message_buffer);
                            this.message_buffer = [];
                        }
                    }
                }, this.message_buffer_delay);

            }

        }else if (this.callbacks.hasOwnProperty(event.name)){
            this.callbacks[event.name](event);
        }

    }

    on(event, callback){
        this.callbacks[event] = callback;
    }

    removeon(event){
        delete this.callbacks[event];
    }

    bind(exchange, routing_key = ''){
        this.rabbitmqconnection.bindQueue(exchange.name, this.name, routing_key);
    }

    unbind(exchange, routing_key = ''){
        this.rabbitmqconnection.unbindQueue(exchange.name, this.name, routing_key);
    }

    delete(){
        if (this.name != '') {
            this.rabbitmqconnection.removeQueue(this.name);
        }
    }

    close() {
        DeviceEventEmitter.removeListener('RabbitMqQueueEvent', this.handleEvent);
        clearTimeout(this.message_buffer_timeout);
        this.callbacks = {};
    }

    basicAck(delivery_tag) {

        this.rabbitmqconnection.basicAck(this.name, delivery_tag);

    }

}

export default Queue;
