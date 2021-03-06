make.rand.binom <- function(p, m, rnd = runif) { function(n) replicate(n, sum(sapply(rnd(m), function(a) { ifelse(p-a <= 0, 0, 1)})))}

#' Poisson distribution random generator
#' 
#' @param lambda Poisson gistribution parameter
#' @param runif FO with produces sequence of uniform values
#' 
#' @return FO witch takes only parameter n- number of values to generate
make.rand.poisson <- function(lambda, rnd = runif) 
{
  e <- exp(-lambda)
  gen_one <- function()
  {
    a <- 1
    k <- 0
    while(a > e)
    {
      a <- a * rnd(1)
      k <- k + 1
    }
    
    return(k - 1)
  }
  
  function(n) replicate(n, gen_one())
}

#' Normal(Gaussian) distribution random generator
#' 
#' @param m mean
#' @param sigma square root of variance
#' 
#' @param N number of random values to generate normal value
#' @param rnd random generator
#' @param rmean theoretical mean of rnd sequence
#' @param rvar theoretical variance of rnd sequence 
#' 
#' @return FO witch takes only parameter n- number of values to generate
make.rand.norm <- function(m = 0, sigma = 1, N = 64, rnd = runif, rmean = 0.5, rvar = 1/12) {
  function(n) replicate(n, sigma*(sum(rnd(N)) - N*rmean) / (sqrt(rvar*N)) + m) 
}

make.rand.weibull <- function(lambda, c, rnd = runif) {
  function(n) (-1/lambda * log(rnd(n)))**(1/c)
}

make.rand.nchisq <- function(k,s) {
  rnd=make.rand.norm(m=sqrt(s/k))
  function(n) sapply(1:n, function(i) sum(rnd(k)^2))
}

#' Pearson Chi-squared test
#' 
#' @param sample Pre-generated sample to test with criterion
#' @param cdfTheor Theoretical CDF
#' @param epsilon Level of significance
#'
#' @return True if test is passed and sample corresponds to the distribution
#' @return False otherwise
test.chisquared <- function(sample, cdfTheor, epsilon) 
{    
  x_minus = min(sample)
  x_plus = max(sample)
  
  k = 20 #Hardcode!
  h = (x_plus-x_minus)/k
  
  lowBordersPractical <- vector("numeric", length = k)
  for (i in 2:k) {
    lowBordersPractical[i] = x_minus+(i-1)*h
  }
  lowBordersPractical[1] = -Inf
  
  p_i <- vector("numeric", length = k)
  for (i in 1:k-1) {
    p_i[i] = cdfTheor(lowBordersPractical[i+1])-cdfTheor(lowBordersPractical[i])
  }
  p_i[k] = 1 - cdfTheor(lowBordersPractical[k])
  
  n_i <- vector("numeric", length = k)
  for (i in 1:length(sample)) {
    j = 1
    while ((lowBordersPractical[j] <= sample[i]) & (j <= k)) {
      j = j + 1
    }
    n_i[j-1] = n_i[j-1]+1
  }
  
  chi_square = 0
  for (i in 1:k) {
    chi_square = chi_square + (n_i[i]-length(sample)*p_i[i])**2/(length(sample)*p_i[i])
  }
  
  delta <- qchisq(1-epsilon, df=k-1)
  
  print(chi_square)
  print(delta)
  if (chi_square < delta) {
    return (TRUE)
  }
  else {
    return (FALSE)
  }
}

#' Kolmogorov test
#' 
#' @param sample Pre-generated sample to test with criterion
#' @param cdfTheor Theoretical CDF
#' @param epsilon Level of significance
#'
#' @return True if test is passed and sample corresponds to the distribution
#' @return False otherwise
test.kolmogorov <- function(sample, cdfTheor, epsilon) 
{    
  #TODO find D
  
  delta <- invkolmog(epsilon) #TODO
  
  if (sqrt(length(sample))*D < delta) {
    return (TRUE)
  }
  else {
    return (FALSE)
  }
}

show <- function (sample) {
  print(
    data.frame(
      row.names = 1, c('Mean', 'Variance'), 
      Counted = c(mean(sample), var(sample)) 
    )
  )
  
  plot(ecdf(sample),verticals = TRUE, lty=1, pch=".",
       col.hor = "black", col.vert = "black")
  xx <- unique(sort(c(seq(-3, 2, length = 201), knots(ecdf(sample)))))
  lines(xx, ecdf(sample)(xx), col = "blue")
  
  ggplot(data.frame("sample"=sample), aes(x=sample), geom = 'blank') +
    geom_histogram(aes(y = ..density..),colour="darkgrey", fill="white", alpha = 0.5) +
    labs(color="")
}

show.binom <- function (p=.347, m=37, n=2500) { 
  show(make.rand.binom(p=p, m=m)(n))
}

show.poisson <- function (n = 10000, lambda = 5) {
  show(make.rand.poisson(lambda)(n))
}

show.normal <- function (m=-3, sigma=4, n=2500) {
  m=-3
  sigma=4
  n=2500
  sample <- make.rand.norm(m, sigma)(n)
  show(sample)
  test.chisquared(sample, function(x) {pnorm(x,m,sigma)}, 0.05)
}

show.weibull <- function (lambda=12, c=23, n=3700) {
  show(make.rand.weibull(lambda, c)(n))
}

show.nchisq <- function (k=4, s=7, n=1500) {
  show(make.rand.nchisq(k,s)(n))
}