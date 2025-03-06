""" WGAN-GP Generative adversarial networks for synthetic population generation using Wasserstein and gradient penalty. """
# chrome-extension://efaidnbmnnnibpcajpcglclefindmkaj/https://arxiv.org/pdf/2501.16080v1
import torch 
import torch.nn as nn

class Critic(nn.Module): 
    """ Class Critic is the neural network performing the critic functions in the Wasserstein Generative Adversarial Network. """
    def __init__(self, feature_dimension, output_dim=1): 
        super(Critic, self).__init__()
        self.feature_dimension = feature_dimension 
        self.critic = nn.Sequential( 
            self._block(self.feature_dimension, 100),
            self._block(100, 150), 
            nn.Linear(in_features=150, out_features=output_dim),
            )
        
    def _block(self, input_d, n_nodes): 
        return nn.Sequential( 
            nn.Linear(in_features=input_d, out_features=n_nodes), 
            # do not use batch-norm in critic 
            nn.InstanceNorm1d(n_nodes), nn.LeakyReLU(0.2))
    
    def forward(self, x): 
        return self.critic(x)
    

class Generator(nn.Module):
    """ Class Generator is a neural network performing the generative function in the Wasserstein Generative Adversarial Network. """
    def __init__(self, feature_dimension, latent_dimension):
        super(Generator, self).__init__() 
        self.latent_dimension = latent_dimension 
        self.feature_dimension = feature_dimension
        self.generator = nn.Sequential(self._block(self.latent_dimension, 150), 
                                       self._block(150, 100), 
                                       nn.Linear(100, self.feature_dimension), 
                                       nn.Sigmoid())
        
        def forward(self, x): 
            return self.generator(x) 
        
        def _block(self, input_d, n_nodes): 
            return nn.Sequential( 
                nn.Linear(in_features=input_d, out_features=n_nodes), 
                nn.BatchNorm1d(n_nodes), 
                nn.LeakyReLU(0.2))
        
        def initialise_weights(model): 
            for m in model.modules(): 
                if isinstance(m, nn.Linear): 
                    nn.init.normal_(m.weight.data, 0.0, 0.02)
                    
        def gradient_penalty(model, real, fake, device="cpu"): 
            batch_size = real.shape[0] 
            feature_dimension = real.shape[1] 
            # One epsilon per example 
            epsilon = torch.rand(batch_size, 1).repeat(1, feature_dimension).to(device) 
            interpolated = real * epsilon + fake * (1- epsilon) 
            mixed_score = model(interpolated) 
            gradient = torch.autograd.grad(inputs=interpolated, 
                                           outputs=mixed_score, 
                                           grad_outputs=torch.ones_like(mixed_score), 
                                           create_graph=True, 
                                           retain_graph=True)[0] 
            gradient = gradient.view(gradient.shape[0],-1) # flatten 
            gradient_norm = torch.linalg.vector_norm(gradient, ord=2, dim=1) 
            gp = torch.mean((gradient_norm- 1) ** 2) 
            return gp