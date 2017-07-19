import React from 'react';

import './CurrentSteps.css';

const CurrentSteps = (props) => {
  const {
    destination,
    solvedAtStep,
    steps,
  } = props;

  const currentStepsOutput = [];

  steps.forEach((step, index) => {
    if (solvedAtStep && index > solvedAtStep) {
      return;
    }

    if (index === 0) {
      currentStepsOutput.push(
        <div className="tooltip" key={step}>
          {step}
          <span className="tooltiptext">beginning</span>
        </div>
      );
    } else {
      currentStepsOutput.push(step);
    }
    currentStepsOutput.push(' → ');
  });

  if (!solvedAtStep) {
    currentStepsOutput.push('... → ');
  }

  currentStepsOutput.push(
    <div className="tooltip" key={destination}>
      {destination}
      <span className="tooltiptext">destination</span>
    </div>
  );

  return (
    <div>
      {currentStepsOutput}
    </div>
  );
}

export default CurrentSteps;
