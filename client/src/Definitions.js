import React from 'react';
import { Link } from 'react-router-dom';

import './Definitions.css';

const Definitions = (props) => {
  const {
    currentUrl,
    destination,
    record,
    step,
  } = props;

  let definitionsOutput;
  if (record) {
    definitionsOutput = [];
    record.forEach((definition, definitionIndex) => {
      const linkedDefinition = definition.linked_definition;
      const key=`${step}-definition-${definitionIndex}`;
      const definitionOutput = [];

      if (record.length > 1) {
        definitionOutput.push(
          <span key={`${key}-number`}>
            {definitionIndex + 1})&nbsp;
          </span>
        );
      }

      let destinationCatched = false;
      linkedDefinition.forEach((definitionPart, definitionPartIndex) => {
        const key = `${step}-definition-${definitionIndex}-part-${definitionPartIndex}`;

        if (definitionPart.type === 'text') {
          definitionOutput.push(
            <span key={key}>
              {definitionPart.text}
            </span>
          );
        } else if (definitionPart.type === 'link') {
          let isDestination = false;
          if (!destinationCatched && (definitionPart.to === destination)) {
            destinationCatched = true;
            isDestination = true;
          }
          definitionOutput.push(
            <Link
              className={isDestination ? 'destination' : ''}
              key={key}
              to={`${currentUrl}/${definitionPart.to}`}
            >
              {definitionPart.text}
            </Link>
          );
        }
      });
      definitionsOutput.push(
        <div
          key={key}
          className="definition"
        >
          {definitionOutput}
        </div>
      );
    });
  } else {
    definitionsOutput = 'Loading...';
  }

  return (
    <div>
      {definitionsOutput}
    </div>
  );
}

export default Definitions;
