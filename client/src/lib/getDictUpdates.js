import fetchServer from './fetchServer';

const getDictUpdates = (currentDict, steps) => {
  if (!steps) {
    return new Promise(resolve => resolve({}));
  }

  const unknownWords = [];
  steps.forEach((step) => {
    if (currentDict[step]) {
      return new Promise(resolve => resolve({}));
    }
    unknownWords.push(step);
  });

  if (unknownWords.length === 0) {
    return new Promise(resolve => resolve({}));
  }

  const unknownWordsQuery =
    unknownWords
      .map((word) => `words[]=${word}`)
      .join('&');

  return fetchServer(`/api/v1/definitions?${unknownWordsQuery}`);
};

export default getDictUpdates;
