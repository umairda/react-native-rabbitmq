import {NativeModules, DeviceEventEmitter} from 'react-native';

const RabbitMqConnection = NativeModules.RabbitMqConnection;

export class Connection {
    
    constructor(config) {
        this.rabbitmqconnection = RabbitMqConnection;
        this.callbacks = {};
        
        this.connected = false;

        DeviceEventEmitter.addListener('RabbitMqConnectionEvent', this.handleEvent);

        this.rabbitmqconnection.initialize(config);
    }
    
    connect() {
        this.rabbitmqconnection.connect();
    }    
    
    close() {
        this.rabbitmqconnection.close();
    }

    clear() {
        DeviceEventEmitter.removeListener('RabbitMqConnectionEvent', this.handleEvent);
    }

    handleEvent = (event) => {

        if ('connected'){ this.connected = true; }

        if (this.callbacks.hasOwnProperty(event.name)){
            this.callbacks[event.name](event)
        }

    }
    
    on(event, callback) {
        this.callbacks[event] = callback;
    } 

    removeon(event) {
        delete this.callbacks[event];
    }
}

export default Connection;