# Express.js

## Project Structure

```
src/
├── index.ts             # Entry point
├── app.ts               # Express app setup
├── config/
│   └── index.ts
├── routes/
│   ├── index.ts         # Route aggregator
│   ├── users.ts
│   └── items.ts
├── controllers/
│   └── userController.ts
├── services/
│   └── userService.ts
├── repositories/
│   └── userRepository.ts
├── middlewares/
│   ├── auth.ts
│   ├── errorHandler.ts
│   └── validate.ts
├── models/
│   └── User.ts
├── types/
│   └── index.ts
└── utils/
```

## Basic Setup

```typescript
// app.ts
import express, { Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { errorHandler } from './middlewares/errorHandler';
import routes from './routes';

const app: Express = express();

// Middlewares
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api', routes);

// Error handler (마지막에 등록)
app.use(errorHandler);

export default app;

// index.ts
import app from './app';
import { config } from './config';

app.listen(config.port, () => {
  console.log(`Server running on port ${config.port}`);
});
```

## Routes

```typescript
// routes/index.ts
import { Router } from 'express';
import userRoutes from './users';
import itemRoutes from './items';

const router = Router();

router.use('/users', userRoutes);
router.use('/items', itemRoutes);

export default router;

// routes/users.ts
import { Router } from 'express';
import { UserController } from '../controllers/userController';
import { auth } from '../middlewares/auth';
import { validate } from '../middlewares/validate';
import { createUserSchema, updateUserSchema } from '../schemas/user';

const router = Router();
const controller = new UserController();

router.get('/', controller.list);
router.get('/:id', controller.getById);
router.post('/', validate(createUserSchema), controller.create);
router.put('/:id', auth, validate(updateUserSchema), controller.update);
router.delete('/:id', auth, controller.delete);

export default router;
```

## Controller

```typescript
// controllers/userController.ts
import { Request, Response, NextFunction } from 'express';
import { UserService } from '../services/userService';
import { AppError } from '../utils/errors';

export class UserController {
  private service = new UserService();

  list = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { page = 1, limit = 20 } = req.query;
      const result = await this.service.list({
        page: Number(page),
        limit: Number(limit),
      });
      res.json(result);
    } catch (error) {
      next(error);
    }
  };

  getById = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const user = await this.service.findById(req.params.id);
      if (!user) {
        throw new AppError('User not found', 404);
      }
      res.json(user);
    } catch (error) {
      next(error);
    }
  };

  create = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const user = await this.service.create(req.body);
      res.status(201).json(user);
    } catch (error) {
      next(error);
    }
  };
}
```

## Middleware

```typescript
// middlewares/errorHandler.ts
import { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/errors';

export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) {
  console.error(err);

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
      },
    });
  }

  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Internal server error',
    },
  });
}

// middlewares/auth.ts
import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt';
import { AppError } from '../utils/errors';

export async function auth(req: Request, res: Response, next: NextFunction) {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      throw new AppError('No token provided', 401, 'UNAUTHORIZED');
    }

    const payload = verifyToken(token);
    req.user = payload;
    next();
  } catch (error) {
    next(new AppError('Invalid token', 401, 'UNAUTHORIZED'));
  }
}

// middlewares/validate.ts
import { Request, Response, NextFunction } from 'express';
import { ZodSchema } from 'zod';
import { AppError } from '../utils/errors';

export function validate(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse(req.body);
      next();
    } catch (error) {
      next(new AppError('Validation failed', 400, 'VALIDATION_ERROR'));
    }
  };
}
```

## Error Class

```typescript
// utils/errors.ts
export class AppError extends Error {
  constructor(
    message: string,
    public statusCode: number = 400,
    public code: string = 'BAD_REQUEST'
  ) {
    super(message);
    this.name = 'AppError';
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string) {
    super(`${resource} not found`, 404, 'NOT_FOUND');
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(message, 401, 'UNAUTHORIZED');
  }
}
```

## Type Extensions

```typescript
// types/express.d.ts
import { User } from '../models/User';

declare global {
  namespace Express {
    interface Request {
      user?: User;
    }
  }
}
```
