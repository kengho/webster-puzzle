import React, { Component } from 'react';
import Scroll from 'react-scroll';

import './PuzzleStep.css';
import Definitions from './Definitions';

class PuzzleStep extends Component {
  componentDidMount() {
    const scroll = Scroll.animateScroll;

    scroll.scrollMore(
      this.stepRef.getBoundingClientRect().bottom,
      { duration: 200 },
    );
  }

  render() {
    const {
      currentUrl,
      destination,
      isLast,
      record,
      step,
    } = this.props;

    return (
      <div
        className={`step-row ${isLast ? 'last' : ''}`}
        ref={(c) => { this.stepRef = c; }}
      >
        <div className="step">
          "{step}":
        </div>
        <div className="definitions">
          {currentUrl && record &&
            <Definitions
              currentUrl={currentUrl}
              destination={destination}
              step={step}
              record={record}
              />
          }
        </div>
      </div>
    );
  }
}

export default PuzzleStep;
