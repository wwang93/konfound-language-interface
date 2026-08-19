# KonFound Language Interface MVP

A standalone local Shiny application that adds a reviewable natural-language layer to `konfound`.
It is intentionally separate from the upstream KonFound repository and does not create a pull request.

## MVP workflow

1. Paste a results paragraph, copied regression table, or statistical software output.
2. Ask the OpenAI Responses API for strict structured extraction.
3. Review each proposed statistic beside its supporting quote.
4. Correct the values and explicitly confirm them.
5. Run the deterministic `konfound::pkonfound()` calculation locally.
6. Inspect the summary, package output, plot, and reproducible R code.

The **Load example** button exercises the full interface without an API key. It is clearly labeled as a built-in example and does not imitate a live AI response.

## Install and run

Open `KonfoundLanguageMVP.Rproj` in RStudio, then run:

```r
source("setup.R")
source("run_app.R")
```

Or from PowerShell:

```powershell
& "C:\Program Files\R\R-4.4.3\bin\Rscript.exe" setup.R
& "C:\Program Files\R\R-4.4.3\bin\Rscript.exe" run_app.R
```

To keep the app on a predictable local address without opening a second browser window:

```powershell
& "C:\Program Files\R\R-4.4.3\bin\Rscript.exe" run_server.R
```

Then open <http://127.0.0.1:3838>. Set `KONFOUND_PORT` before starting if port 3838 is already in use.

## Add the OpenAI API key later

1. Copy `.Renviron.example` to `.Renviron` in this project.
2. Replace `your_api_key_here` with the real key.
3. Restart R so the environment is reloaded.
4. Confirm that the interface shows **API ready**.

Do not paste a key into the Shiny browser UI, source code, Git history, screenshots, or chat. `.Renviron` is excluded by `.gitignore`. The R backend reads the key and sends the request directly to `https://api.openai.com/v1/responses`.

`OPENAI_MODEL` defaults to `gpt-5.6-sol` and can be changed in `.Renviron` without editing code.

## Data boundary

- UI state and KonFound calculations stay on the local computer.
- Clicking **Extract statistics** sends the pasted text to the OpenAI API.
- The request uses Structured Outputs and `store = false`.
- Clicking **Load example** does not call OpenAI.
- The model output is never treated as a final calculation input until the user reviews and confirms it.

Avoid submitting restricted, identifiable, or unpublished text unless its use with the configured API account is permitted.

## Current scope

The MVP supports continuous-outcome linear models, dichotomous-outcome logistic models, and 2 x 2 inputs exposed by `pkonfound()`. It extracts one focal model per request. PDF parsing, Word upload, multi-model comparison, OCR, authentication, shared deployment, and persistent storage are deliberately out of scope.

## Tests

```r
testthat::test_dir("tests/testthat")
```

The live OpenAI call is not exercised in automated tests; it requires the project-local API key and intentionally remains a manual acceptance test.
