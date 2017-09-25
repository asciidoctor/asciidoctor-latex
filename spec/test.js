const asciidoctorLatex = require('../dist/main.js')();

const doc = `[env.question]\n\
--\n\
What is the speed of light?\n\
--\n\
\n\
[click.answer]\n\
--\n\
300,000 km/sec\n\
--`;

console.log(asciidoctorLatex.$convert(doc));
