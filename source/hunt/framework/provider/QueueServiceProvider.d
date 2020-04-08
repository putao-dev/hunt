module hunt.framework.provider.QueueServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.queue;

import hunt.amqp.client;
import hunt.redis;
import hunt.logging.ConsoleLogger;

import poodinis;

/**
 * 
 */
class QueueServiceProvider : ServiceProvider {

    override void register() {
        container.register!(AbstractQueue)(&buildWorkder).singleInstance();
    }

    protected AbstractQueue buildWorkder() {
        AbstractQueue _queue;
        ApplicationConfig config = container.resolve!ApplicationConfig();

        string typeName = config.queue.driver;
        if (typeName == AbstractQueue.MEMORY) {
            _queue = new MemoryQueue();
        } else if (typeName == AbstractQueue.AMQP) {
            auto amqpConf = config.amqp;

            AmqpClientOptions options = new AmqpClientOptions()
            .setHost(amqpConf.host)
            .setPort(amqpConf.port)
            .setUsername(amqpConf.username)
            .setPassword(amqpConf.password);

            // AmqpPool pool = new AmqpPool(options);
            // _queue = new AmqpQueue(pool);
            AmqpClient client = AmqpClient.create(options);
            _queue = new AmqpQueue(client);
        } else if (typeName == AbstractQueue.REDIS) {
            
            RedisPool pool = container.resolve!RedisPool();
            _queue = new RedisQueue(pool);
        } else {
            warningf("No queue driver defined %s", typeName);
        }

        return _queue;
    }
}
