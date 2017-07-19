import React from 'react';

import './Controls.css';
import DifficultyInput from './DifficultyInput';

const Controls = (props) => {
  const {
    difficultyChangeHandler,
    fetchError,
    fetchPending,
    selectedDifficulty,
    startPuzzle,
    startPuzzleText,
  } = props;

  const difficultyInputsOutput = [];
  ['ANY', 'EASY', 'MEDIUM', 'HARD'].forEach((difficulty) => {
    difficultyInputsOutput.push(
      <DifficultyInput
        difficultyChangeHandler={difficultyChangeHandler}
        key={difficulty}
        selectedDifficulty={selectedDifficulty}
        value={difficulty}
      />
    );
  });

  return (
    <div>
      <div className="difficulty">
        {difficultyInputsOutput}
      </div>
      <div className="start-puzzle">
        <button disabled={fetchPending ? true : false} onClick={startPuzzle}>
          {startPuzzleText}
        </button>
      </div>
      <div>
        {fetchError &&
          <div>Sorry, something went wrong, please try later.</div>
        }
      </div>
    </div>
  );
}

export default Controls;
