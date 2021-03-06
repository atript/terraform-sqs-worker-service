const aws = require('aws-sdk');
const { CONFIG, timeout, frequency } = process.env;
const sqs = new aws.SQS();
const ecs = new aws.ECS();
const triggerDefinitions = JSON.parse(CONFIG);
const msTimeout = timeout * 1000;
const msFrequency = frequency * 1000;

//index
module.exports.sqs_trigger = function(event, context) {
  console.log(
    `timeout - ${timeout}\nfrequency - ${frequency}\nCONFIG - ${CONFIG}`
  );
  console.log('Setup inteval', msFrequency);
  const intervalId = setInterval(() => {
    const tasks = triggerDefinitions.map(runScalingStrategy);
    console.log('Run interval for triggerDefinitions', tasks.length);
  }, msFrequency);
  return new Promise(resolve => {
    setTimeout(() => {
      clearInterval(intervalId);
      resolve();
    }, msTimeout - 1000);
  });
};

function runScalingStrategy(config) {
  switch (config.scaling_strategy) {
    case 'SCALE_TILL_MAX_REACHED':
      return maxReachScalingStrategy(config);
    default:
      return defaultScalingStrategy(config);
  }
}

async function maxReachScalingStrategy(config) {
  console.log(`maxReachScalingStrategy run`, config);
  const { service, cluster, QueueUrl, max_tasks_count } = config;
  console.log(`check ${QueueUrl} for messages`);
  const maxTasksCount = parseInt(max_tasks_count, 10);

  const { runningCount, desiredCount } = await getCurrentTaskCount(
    service,
    cluster
  );

  if (runningCount < desiredCount) {
    console.log(
      `skipped due to runningTaskCount ${runningCount} < desiredTaskCount ${desiredCount}`
    );
    return;
  }

  const {
    ApproximateNumberOfMessages = 0,
    ApproximateNumberOfMessagesNotVisible = 0
  } = await getApproximateCounters(QueueUrl);

  const numberOfMessages =
    ApproximateNumberOfMessages + ApproximateNumberOfMessagesNotVisible;

  console.log(`${numberOfMessages} found`);

  if (ApproximateNumberOfMessages > 0 && desiredCount < maxTasksCount) {
    return setDesiredCount(service, cluster, desiredCount + 1);
  }

  if (numberOfMessages === 0 && runningCount !== 0) {
    return setDesiredCount(service, cluster, 0);
  }
}

async function defaultScalingStrategy(config) {
  console.log(`defaultScalingStrategy run`, config);
  const { service, cluster, QueueUrl } = config;
  console.log(`check ${QueueUrl} for messages`);

  const { runningCount } = await getCurrentTaskCount(service, cluster);

  const {
    ApproximateNumberOfMessages = 0,
    ApproximateNumberOfMessagesNotVisible = 0
  } = await getApproximateCounters(QueueUrl);

  const numberOfMessages =
    ApproximateNumberOfMessages + ApproximateNumberOfMessagesNotVisible;

  console.log(`${numberOfMessages} found`);

  if (numberOfMessages > 0 && runningCount === 0) {
    return setDesiredCount(service, cluster, 1);
  }

  if (numberOfMessages === 0 && runningCount !== 0) {
    return setDesiredCount(service, cluster, 0);
  }
}

async function getQueueAttributes(QueueUrl, AttributeNames) {
  const { Attributes } = await sqs
    .getQueueAttributes({
      QueueUrl,
      AttributeNames
    })
    .promise();

  return Attributes;
}

async function getApproximateCounters(QueueUrl) {
  const {
    ApproximateNumberOfMessages,
    ApproximateNumberOfMessagesNotVisible
  } = await getQueueAttributes(QueueUrl, [
    'ApproximateNumberOfMessages',
    'ApproximateNumberOfMessagesNotVisible'
  ]);
  return {
    ApproximateNumberOfMessages: parseInt(ApproximateNumberOfMessages, 10),
    ApproximateNumberOfMessagesNotVisible: parseInt(
      ApproximateNumberOfMessagesNotVisible,
      10
    )
  };
}

function setDesiredCount(service, cluster, desiredCount) {
  return ecs
    .updateService({
      cluster,
      service,
      desiredCount
    })
    .promise();
}

async function getCurrentTaskCount(service, cluster) {
  const {
    services: [{ desiredCount, runningCount }]
  } = await ecs
    .describeServices({
      cluster,
      services: [service]
    })
    .promise();
  return { desiredCount, runningCount };
}
