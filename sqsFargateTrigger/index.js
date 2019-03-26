const aws = require('aws-sdk');

const {
  CONFIG,
  timeout,
  frequency
} = process.env;

const sqs = new aws.SQS();
const ecs = new aws.ECS();
const triggerConfig = JSON.parse(CONFIG);
const msTimeout = timeout * 1000;
const msFrequency = frequency * 1000;
module.exports.sqs_trigger = async (event, context) => {
  console.log(`timeout - ${timeout}\nfrequency - ${frequency}\nCONFIG - ${CONFIG}`)
  return new Promise((resolve, reject) => {
    setInterval(() => Promise.all(triggerConfig.map( async ({service, cluster, QueueUrl}) => {
      console.log(`check ${QueueUrl} for messages`);
      const { Attributes: { ApproximateNumberOfMessages, ApproximateNumberOfMessagesNotVisible }} = await sqs.getQueueAttributes({QueueUrl, AttributeNames: ["ApproximateNumberOfMessages", "ApproximateNumberOfMessagesNotVisible"]}).promise();
      const {taskArns}  = await ecs.listTasks({
        cluster: cluster,
        serviceName: service,
        desiredStatus: 'RUNNING',
        launchType: 'FARGATE'
      }).promise();
      const numberOfMessages = parseInt(ApproximateNumberOfMessages, 10) + parseInt(ApproximateNumberOfMessagesNotVisible, 10)
      numberOfMessages && console.log(`${numberOfMessages} found`);
      if(numberOfMessages > 0 && taskArns.length === 0) {
        return await scaleUpFargate(service, cluster);
      } else if(numberOfMessages === 0 && taskArns.length !== 0) {
        return await scaleDownFargate(service, cluster)
      }
      return Promise.resolve();
    })), msFrequency)
    setTimeout(resolve, msTimeout - 1000);
  })
  
}

async function scaleUpFargate(service,cluster) {
  console.log(`scale ${service} up`);
  return await ecs.updateService({
    cluster,
    service,
    desiredCount: 1
  }).promise();
}
async function scaleDownFargate(service,cluster) {
  console.log(`scale ${service} down`);
  return await ecs.updateService({
    cluster,
    service,
    desiredCount: 0
  }).promise();
}
