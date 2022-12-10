import puppeteer from 'puppeteer-core';

const port = 9222;
const username = 'admin';
const password = '!fOrmerfOrmer01';

(async () => {
  const browser = await puppeteer.connect({
    browserURL: 'http://127.0.0.1:' + port,
  });
  const context = await browser.createIncognitoBrowserContext();
  const page = await context.newPage();

  await page.authenticate({ username, password });

  await page.goto('https://homepage.home/');

  //   // Type into search box.
  //   await page.type('.devsite-search-field', 'Headless Chrome');

  //   // Wait for suggest overlay to appear and click "show all results".
  //   const allResultsSelector = '.devsite-suggest-all-results';
  //   await page.waitForSelector(allResultsSelector);
  //   await page.click(allResultsSelector);

  //   // Wait for the results page to load and display the results.
  //   const resultsSelector = '.gsc-results .gs-title';
  //   await page.waitForSelector(resultsSelector);

  //   // Extract the results from the page.
  //   const links = await page.evaluate(resultsSelector => {
  //     return [...document.querySelectorAll(resultsSelector)].map(anchor => {
  //       const title = anchor.textContent.split('|')[0].trim();
  //       return `${title} - ${anchor.href}`;
  //     });
  //   }, resultsSelector);

  //   // Print all the files.
  //   console.log(links.join('\n'));

  // await browser.close();
})();
