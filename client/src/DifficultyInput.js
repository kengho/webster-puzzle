import React from 'react';

import './DifficultyInput.css';

const DifficultyInput = (props) => {
  const {
    difficultyChangeHandler,
    selectedDifficulty,
    value,
  } = props;

  return (
    <div className="difficulty-input">
      <input
        checked={selectedDifficulty === value}
        id={value}
        name="difficulty"
        onChange={difficultyChangeHandler}
        type="radio"
        value={value}
      />
      <label htmlFor={value}>
        {value}
      </label>
    </div>
  );
}

export default DifficultyInput;
