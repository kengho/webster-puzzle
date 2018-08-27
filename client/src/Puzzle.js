import React, { Component } from 'react';
import clone from 'clone';

import './Puzzle.css';
import Controls from './Controls';
import CurrentSteps from './CurrentSteps';
import PuzzleStep from './PuzzleStep';

import fetchServer from './lib/fetchServer';
import getDictUpdates from './lib/getDictUpdates';

class Puzzle extends Component {
  constructor(props) {
    super(props);

    const { destination, steps } = this.getSteps(props);
    const { solvedAtStep, stepsMap } = this.processSteps(destination, steps);
    this.state = {
      destination: props.match.params.destination,
      dict: {},
      fetchError: false,
      fetchPending: false,
      selectedDifficulty: 'EASY',
      solvedAtStep,
      steps,
      stepsMap,
    };

    this.difficultyChangeHandler = this.difficultyChangeHandler.bind(this);
    this.getSteps = this.getSteps.bind(this);
    this.processSteps = this.processSteps.bind(this);
    this.startPuzzle = this.startPuzzle.bind(this);
    this.updateState = this.updateState.bind(this);
  }

  // Update state after clicking on link.
  componentWillReceiveProps(nextProps) {
    this.updateState(nextProps);
  }

  // Update state if user came here directly via url.
  componentDidMount() {
    this.updateState(this.props);
  }

  difficultyChangeHandler(evt) {
    this.setState({ selectedDifficulty: evt.target.value });
  }

  getSteps(props) {
    const stepsParam = props.match.params.steps;
    const steps = stepsParam && stepsParam.split('/');

    return { destination: props.match.params.destination, steps };
  }

  processSteps(destination, steps, dictCopy) {
    let solvedAtStep = false;
    const stepsMap = [];
    if (!this.state) {
      return { solvedAtStep, stepsMap };
    }

    if (destination && steps) {
      let currentUrl = `/${destination}`;
      if (process.env.REACT_APP_RELATIVE_URL_ROOT) {
        currentUrl = `${process.env.REACT_APP_RELATIVE_URL_ROOT}${currentUrl}`
      }

      const usedWords = [];
      steps.forEach((step, stepIndex) => {
        usedWords.push(step);

        // '/end' => '/end/a' => '/end/a/b' => '/end/a/b/c'
        currentUrl = `${currentUrl}/${step}`;

        if (dictCopy && dictCopy[step]) {
          const record = dictCopy[step];
          record.forEach((definition) => {
            const linkedDefinition = definition.linked_definition;
            linkedDefinition.forEach((definitionPart) => {
              // TODO: use definitions.links instead.
              if (definitionPart.type === 'link') {
                if (!solvedAtStep && (definitionPart.to === destination)) {
                  solvedAtStep = stepIndex;
                }

                // Delete links to already used words.
                if (usedWords.indexOf(definitionPart.to) !== -1) {
                  definitionPart.type = 'text';
                }

                // Delete links which leads to the next step
                // (it means that next step is loaded already).
                if (definitionPart.to === steps[stepIndex + 1]) {
                  definitionPart.type = 'text';
                }
              }
            });
          });

          stepsMap.push({ step, record, currentUrl, includesDestination: solvedAtStep });
        }
      });
    }

    return { solvedAtStep, stepsMap };
  }

  startPuzzle() {
    // Disable start button.
    this.setState({ fetchPending: true });

    let difficultyParam = '';
    if (this.state.selectedDifficulty !== 'ANY') {
      difficultyParam = `?difficulty=${this.state.selectedDifficulty.toLowerCase()}`;
    }
    fetchServer(`/api/v1/puzzles${difficultyParam}`)
      .then((json) => {
        if (json.errors) {
          this.setState({
            fetchError: true,

            // Enable start button.
            fetchPending: false,
          });
          return;
        }

        const data = json.data;
        const firstStep = data.beginning;

        const record = {};

        // TODO: throw erorr if definitions are empty.
        record[data.beginning] = data.beginning_definitions;
        const dict = { ...{}, ...record, ...this.state.dict }

        const { solvedAtStep, steps, stepsMap } = this.processSteps(
          data.destination,
          [firstStep],
          dict,
        );
        this.setState({
          destination: data.destination,
          dict,
          fetchError: false,
          fetchPending: false,
          solvedAtStep,
          steps,
          stepsMap,
        });

        let newPath = `/${data.destination}/${firstStep}`;
        if (process.env.REACT_APP_RELATIVE_URL_ROOT) {
          newPath = `${process.env.REACT_APP_RELATIVE_URL_ROOT}${newPath}`;
        }
        this.props.history.push(newPath);
      });
  }

  updateState(props) {
    const { destination, steps } = this.getSteps(props);
    getDictUpdates(this.state.dict, steps)
      .then((json) => {
        if (json.errors) {
          this.setState({
            fetchError: true,

            // Enable start button.
            fetchPending: false,
          });
          return;
        }

        // Even if data is empty, state should be updated
        // because steps may have changed.

        const definitions = json.data ? json.data.definitions : {};
        const dict = { ...{}, ...definitions, ...this.state.dict }

        // Object.assign and Spread doesn't preventing deep mutations of dict,
        // using clone library instead.
        const { solvedAtStep, stepsMap } = this.processSteps(destination, steps, clone(dict));
        this.setState({
          destination,
          dict,
          fetchError: false,
          solvedAtStep,
          steps,
          stepsMap,
        });
      });
  }

  render() {
    const {
      destination,
      fetchError,
      fetchPending,
      selectedDifficulty,
      solvedAtStep,
      steps,
      stepsMap,
    } = this.state;

    let errors;
    let puzzleSteps;
    if (!fetchError) {
      puzzleSteps = [];
      stepsMap.forEach((stepMap, index) => {
        const { step, record, currentUrl } = stepMap;
        const isLast = (index === stepsMap.length - 1);
        puzzleSteps.push(
          <PuzzleStep
            currentUrl={currentUrl}
            destination={destination}
            isLast={isLast}
            key={`puzzle-step-${step}`}
            record={record}
            step={step}
          />
        );
      });
    }

    const startPuzzleText = steps ? 'try another puzzle' : 'start';

    // FIXME: for some reason "puzzles" with path_size == 2 are not solving immediately.
    //   See https://kengho.tech/webster-puzzle/volumescope/volumenometry
    return (
      <div>
        <div className={`controls ${steps ? 'top-center' : 'center-center'}`}>
          <Controls
            difficultyChangeHandler={this.difficultyChangeHandler}
            fetchError={fetchError}
            fetchPending={fetchPending}
            selectedDifficulty={selectedDifficulty}
            startPuzzle={this.startPuzzle}
            startPuzzleText={startPuzzleText}
          />
        </div>
        {steps && !errors &&
          <div className="puzzle">
            <div className="current-steps">
              <CurrentSteps
                destination={destination}
                solvedAtStep={solvedAtStep}
                steps={steps}
              />
            </div>
            <div className="steps">
              {puzzleSteps}
            </div>
            <div className={`solved ${solvedAtStep ? 'animate' : ''}`}>
              solved
            </div>
          </div>
        }
      </div>
    );
  }
}

export default Puzzle;
