module.exports = {
  testEnvironment: 'node',
  testMatch: ['<rootDir>/backend/**/*.test.ts'],
  transform: { '^.+\\.tsx?$': ['ts-jest', { tsconfig: 'tsconfig.test.json' }] },
  moduleNameMapper: { '^(\\.{1,2}/.*)\\.js$': '$1' },
  clearMocks: true,
  modulePathIgnorePatterns: ['<rootDir>/tmp/', '<rootDir>/out/', '<rootDir>/output/'],
};
